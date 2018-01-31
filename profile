/*
*   EchoSistant Evolution - The Ultimate Voice Assistant Using Your Alexa Enabled Device.
*
*   Based off the idea of V1-V4 Written by Jason Headley & Bobby Dobrescu
*   Copyright 2018 EchoSistant Team (Anthony Santilli, Corey Lista, Jason Headley, Bobby Dobrescu)
*
*   Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
*   in compliance with the License. You may obtain a copy of the License at:
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
*   on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
*   for the specific language governing permissions and limitations under the License.
*
// /**********************************************************************************************************************************************/
import groovy.json.*
import java.text.SimpleDateFormat
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import java.security.InvalidKeyException
import java.security.MessageDigest

include 'asynchttp_v1'

definition(
    name			: "EchoSistant5",
    namespace		: "${childNameSpace()}",
    author			: "JH/BD",
    description		: "The Ultimate Voice Controlled Assistant Using Alexa Enabled Devices.",
    category		: "My Apps",
    singleInstance	: true,
    iconUrl			: "https://echosistant.com/es5_content/images/es5_logo.png",
    iconX2Url		: "https://echosistant.com/es5_content/images/es5_logo.png",
    iconX3Url		: "https://echosistant.com/es5_content/images/es5_logo.png")
/**********************************************************************************************************************************************/
private releaseVer() { return "5.0.0117" }
private appVerDate() { "1-17-2018" }
/**********************************************************************************************************************************************/
preferences {
    page name: "startPage"
    page name: "prereqPage"
    page name: "preInstallPage"
    page name: "mainPage"
    page name: "locPrefPage"
    page name: "reviewSetupPage"
    page name: "profConfigPage"
    page name: "manageProfilesPage"
    page name: "notifPrefPage"
    page name: "timeRestrictPage"
    page name: "changeLogPage"
    page name: "awsStackConfigPage"
    page name: "awsSkillConfigPage"
    page name: "codeUpdatesPage"
    page name: "pDefaults"
    page name: "helpPage"
    page name: "uninstallPage"
    page name: "securityPage"
    page name: "profiles"
    page name: "settingsPage"
    page name: "tokens"
    page name: "tokenResetConfirmPage"
    page name: "tTokenReset"
    page name: "awsSkillAuthGenPage"
    page name: "processActionsPage"
}

mappings {
    path("/process") { action: [POST: "procLambdaCmds", GET: "lambdaStateUpdData"] }
    path("/stupdate") { action: [GET: "stUpdateHtml"] }
    path("/strooms") { action: [GET: "stRoomsHtml"] }
    path("/stackResp") { action: [POST: "lambdaSetupRespHandler"] }
    path("/awsutil") { action: [GET: "awsUtilHtml"] }
    path("/rDataCol") { action: [POST: "processRoomData"] }
    path("/getDevMap") { action: [GET: "getPrettyDevMap"] }
    path("/getLocMap") { action: [GET: "getPrettyLocMap"] }
    path("/getDbData") { action: [GET: "dbDataMap"] }
    path("/getRefPage") { action: [GET: "getRefPage"] }
    // path("/getColorNames") { action: [GET: "getColorNameMap"] }
    // path("/getColorMap") { action: [GET: "getColorMap"] }
}

def startPage() {
    if(!atomicState?.accessToken) { getAccessToken() }
	atomicState.ok2InstallProfFlag = false
	if(atomicState?.notificationPrefs == null) { atomicState?.notificationPrefs = buildNotifPrefMap() }
	def preReqOk = (atomicState?.preReqTested == true) ? true : preReqCheck()
	def stateSz = getStateSizePerc()
	if(!atomicState?.accessToken || (!atomicState?.isInstalled && !preReqOk) || (stateSz > 80)) {
		return dynamicPage(name: "startPage", title: "Status Page", nextPage: "", install: false, uninstall: false) {
			section ("Status Page:") {
				def title = ""
                def desc = ""
				if(!atomicState?.accessToken) { title="OAUTH Error"; desc = "OAuth is not Enabled for ${appName()} application.  Please click remove and review the installation directions again"; }
				else if(!preReqOk) { title="SmartThings Location Error"; desc = "SmartThings Location is not returning (TimeZone: ${location?.timeZone}) or (ZipCode: ${location?.zipCode}) Please edit these settings under the ST IDE or Mobile App"; }
				else { title="Unknown Error"; desc = "Application Status has not received any messages to display";	}
				if(stateSz > 80) { title="App Storage Full"; desc += "${desc != "" ? "\n\n" : ""}Your Echosistant App State Usage is Greater than 80% full.  This is not normal and you should notify the developer."; }
				LogAction("Status Message: $desc", "warn", true)
				paragraph title: "$title", "$desc", required: true, state: null
			}
		}
	}
	if(getLastWebUpdSec() > 300) { updateWebStuff(true) }
    if(!atomicState?.isInstalled) { preInstallPage() }
    else if(showChgLogOk()) { return changeLogPage() }
    // else if(showDonationOk()) { return donationPage() }
    else { return mainPage() }
}

def preInstallPage() {
    return dynamicPage(name: "preInstallPage", title: "", nextPage: "", install: true, uninstall: false) {
        section("") {
            image getAppImg("welcome_img.png")
            paragraph title: "Why Am I Seeing This Page?", "In order to use the amazing new install automation to this app it needs to be installed before going through the setup process.\n\nPlease Press Save and when returned to the main menu go to ${app?.label} to resume setup process."
        }
    }
}

def mainPage() {
    def storageApp = getStorageApp()
    def isInstalled = atomicState?.isInstalled
    Boolean setComplete = (atomicState?.newSetupComplete == true && isInstalled == true && atomicState?.installData?.shownSharePref == true)
    dynamicPage(name: "mainPage", title:"", nextPage: (!setComplete ? "reviewSetupPage" : null), install: setComplete, uninstall:false) {
        section("") {
            // image description: "Test Title", getAppImg("es5_logo.png")
            log.debug getAppEndpointUrl("getDevMap")
            href "changeLogPage", title: "", description: "${appInfoDesc()}", image: getAppImg("es5_logo.png")
        }
        if(!storageApp) {
            section("Required Module Missing") {
                paragraph "Please install the ES-Storage smartapp from the IDE and reload this page", required: true, state: null
            }
        } else {
            section("Getting Started Videos", hideable: true, hidden: atomicState?.isInstalled) {
                element(name: "videoElement", element: "video", type: "video", title: "Lambda Setup Video", description: "Lambda Setup Walkthrough", required: false, 
                    image: getAppImg("welcome_main.png"), video: "http://f.cl.ly/items/3O2L03471l2K3E3l3K1r/Zombie%20Kid%20Likes%20Turtles.mp4")
            }
            section ("Step 1: Location Setup") {
                input "defaultInvocation", "text", title: "Default Skill Name", description: "This will be the default phrase used for this app\nOK Alexa, Tell the '${settings?.defaultInvocation ?: "House"}' to turn off the living room lights",
                        defaultValue: "House", image: getAppImg("es5_int_name.png"), submitOnChange: true
                def t0 = getLocPrefsDesc()
                href "locPrefPage", title: "Manage Location Items", description: (t0 ? "${t0}\n\nTap to modify" : "Tap to configure"), state: (t0 ? "complete" : null), image: getAppImg("es5_select.png")
            }
            section ("Step 2: Profiles|Rooms Settings") {
                href "profConfigPage", title: "Configure Profiles/Rooms", description: mRoomsD(), state: profsAreConfigured(), image: getAppImg("es5_rooms.png")
            }
            section ("Step 3: AWS Stack & Alexa Skills") {
                def t0 = getAwsStackDesc()
                href "awsStackConfigPage", title: "Amazon AWS", description: (lambdaIsConfigured() ? "${t0}\n\nTap to view" : "Tap to configure"), required: true, state: (lambdaIsConfigured() ? "complete" : null), image: getAppImg("es5_setup.png")
                def t1 = getSkillDesc()
                if(lambdaIsConfigured()) {
                    href "awsSkillConfigPage", title: "Alexa Skills", description: (t1 ? "${t1}\n\nTap to manage" : "Tap to configure"), required: (lambdaIsConfigured() && !t1), state: (t1 ? "complete" : null), image: getAppImg("es5_skills.png")
                }
            }
            section ("Step 4: General Settings & Notifications") {
                def t0 = getAppSettingsDesc()
                href "settingsPage", title: "General Settings", description: (t0 ? "${t0}\n\nTap to modify" : "Tap to configure"), state: (t0 ? "complete" : null), image: getAppImg("es5_settings.png")
                def t1 = getAppNotifConfDesc()
                href "notifPrefPage", title: "Notifications", description: (t1 ? "${t1}\n\nTap to modify" : "Tap to configure"), state: (t1 ? "complete" : null), image: getAppImg("es5_speech.png")
                def t2 = getSecSettingsDesc()
                href "securityPage", title: "Security Settings", description: (t2 ? "${t2}\n\nTap to modify" : "Tap to configure"), state: (t2 ? "complete" : null), image: getAppImg("es5_security.png")
            }
            if(lambdaIsConfigured() && appData?.updater?.allowInApp != false) {
                section ("Updates") {
                    def updDesc = whichUpdatesAvail()
                    href "codeUpdatesPage", title: "Software Updater", description: "${updDesc ? "Updates Available:\n${updDesc}\n\n" : ""}Tap here to update", state: "complete", image: getAppImg("es5_update.png")
                }
            }
            section ("Help & Reference"){
                href "helpPage", title: "Help | Troubleshooting", description: "", image: getAppImg("es5_help.png")
                href url: getAppEndpointUrl("getRefPage"), style:"external", title:"View Reference Page", description: "Tap to view Data", required:false, image: getAppImg("es5_reference.png")
            }
            section("Remove All Apps, and Profiles:") {
                href "uninstallPage", title: "Uninstall this App", description: "", image: getAppImg("es5_uninstall.png")
            }
        }
        atomicState?.ok2RunInitialize = true
        atomicState.ok2InstallProfFlag = true
    }
}

def locPrefPage() {
	return dynamicPage(name: "locPrefPage", title: "Location Preferences", install: false, uninstall: false) {
        section("Manage Users: (Experimental)") {
            paragraph title: "What are the Users For?", "This will be used in AWS to help identify users(if Available)\nPlease list all names separated by a ,"
            input "usersAvailable", "text", title: "Available Users", required: false, image: getAppImg("user_add.png"), submitOnChange: true
        }
        section("Manage Modes | Routines Used in Command Matching") {
            paragraph title: "What are these for?", "Any selected items will not be sent up to AWS and used to match voice commands."
            def routines = location.helloHome?.getPhrases()?.sort {it?.label }?.collect { [(it?.id):it?.label] }
            input "excludedRoutines", "enum", title: "Don't Use these Routines", required: false, multiple: true, options: routines, submitOnChange: true, image: getAppImg("routine.png")
            def modes = location?.modes?.sort{it?.name}?.collect { [(it?.id):it?.name] }
            input "excludedModes", "enum", title: "Don't Use these Modes", required: false, multiple: true, options: modes, submitOnChange: true, image: getAppImg("mode.png")
        }
        section("View Device | Location Data") {
            // log.debug "devMap: ${getAppEndpointUrl("getDevMap")}"
            // log.debug "locMap: ${getAppEndpointUrl("getLocMap")}"
            href url: getAppEndpointUrl("getDevMap"), style:"external", title:"View the Device Data for Debug", description: "Tap to view Data", required:false, image: getAppImg("view.png")
            href url: getAppEndpointUrl("getLocMap"), style:"external", title:"View the Location Data for Debug", description: "Tap to view Data", required:false, image: getAppImg("view.png")
        }
    }
}

def getLocPrefsDesc() {
	def str = ""
    str += (settings?.usersAvailable || settings?.excludedRoutines || settings?.excludedModes) ? "Available Items:\n" : ""
    str += settings?.usersAvailable ? " • Users: (${settings.usersAvailable?.toString().split(",")?.size()})" : ""
    str += settings?.excludedRoutines ? "${str != "" ? "\n" : ""} • Routines: (${getFilteredRoutines()?.size()})" : ""
	str += settings?.excludedModes ? "${str != "" ? "\n" : ""} • Modes: (${getFilteredModes()?.size()})" : ""
	return str != "" ? str : null
}

def reviewSetupPage() {
	return dynamicPage(name: "reviewSetupPage", title: "", install: true, uninstall: false) {
		if(!atomicState?.newSetupComplete) { atomicState.newSetupComplete = true }
		section("Setup Summary:") {
			def str = ""
            str += "Profiles:\n" + mRoomsD(true)
            def t0 = getLocPrefsDesc()
            def t1 = getAppSettingsDesc()
            def t2 = getAppNotifConfDesc()
            def t3 = getSecSettingsDesc()
            str += t0 ? "\n\nLocation Prefs:\n${t0}" : ""
            str += t1 ? "\n\nSettings:\n${t1}" : ""
            str += t2 ? "\n\nNotifications:\n${t2}" : ""
            str += t3 ? "\n\nSecurity:\n${t3}" : ""
			paragraph title: "Review Configuration", "${str}"
		}
        showDevSharePrefs()
		def iData = atomicState?.installData ?: [:]
		iData["shownSharePref"] = true
		atomicState?.installData = iData
        mobileCltTypeSect()
        awsLocaleSection()
        if(atomicState?.isInstalled) {
            section("Remove All Apps, and Profiles:") {
                href "uninstallPage", title: "Uninstall this App", description: "", image: getAppImg("uninstall.png")
            }
        }
	}
}

def settingsPage() {
    def storApp = getStorageApp()
    dynamicPage(name: "settingsPage", uninstall: false, install: false) {
        section ("Alexa Global Voice Settings") {
            input "feedbackType", "enum", title: "Alexa Feedback Type", required: false, defaultValue: "default", submitOnChange: true,
                   options:  ["default":"Default Answers","short":"Short Answers","none":"None", "disable":"Disable"], image: getAppImg("voice_feedback.png")
            if(settings?.feedbackType in ["default", "short"]) {
                def t1 = getRestrictSchedDesc("reply")
                href "timeRestrictPage", title: "Restrict when Feedback is Given", description: (t1 ?: "Tap to configure"), state: (t1 ? "complete" : null), image: getAppImg("restriction.png"), params: ["sData":["prefix":"reply"]]
                def fuDesc = "Always Ask if you Need Something Else?"
                input "followupMode", "bool", title: "Followup Mode", description: fuDesc, required: false, defaultValue: false, image: getAppImg("followup_mode.png"), submitOnChange: true
            }
            def t1 = getRestrictSchedDesc("quietMode")
            href "timeRestrictPage", title: "Enable Night Mode on a Schedule", description: (t1 ?: "Tap to configure"), state: (t1 ? "complete" : null), image: getAppImg("restriction.png"), params: ["sData":["prefix":"quietMode"]]
            def wmDesc = "Whisper All Responses"
            input "quietMode", "bool", title: "Night Mode Enabled", description: wmDesc, required: false, defaultValue: false, image: getAppImg("night_mode.png"), submitOnChange: true
            input "disFollowupOnQuietMode", "bool", title: "Disable Followup in Night Mode?", description: "", required: false, defaultValue: false, image: getAppImg("night_mode.png"), submitOnChange: true
            def apDesc = "She will suprise you with her replies..."
            input "allowPersonality", "bool", title: "Random Alexa Personality", description: apDesc, required: false, defaultValue: true, image: getAppImg("random_personality.png"), submitOnChange: true
        }
        section ("Device Commands") {
            def sdcaDesc = "This will allow the app to skip a device command that it is already in the state of the current command requested"
            input "sendDevCmdsAlways", "bool", title: "Enable Command Optimization?", description: sdcaDesc, required: false, defaultValue: true, submitOnChange: true, image: getAppImg("optimize.png")
            def tmDesc = "This will simulate the full experience but not execute the device commands."
            input "testMode", "bool", title: "Test Mode\nDon't Run Device Commands", description: tmDesc, required: false, defaultValue: false, image: getAppImg("test_mode.png"), submitOnChange: true
        }
        section("Echo Device Options") {
            input "showBgWallpaper", "enum", title: "Echo Show Background", required: false, defaultValue: "carbon_fiber" , submitOnChange: true, image: getAppImg("wallpaper.png"),
                   options:  [
                        "carbon_fiber":"Carbon Fiber (Default)", "none":"None", "red":"Red", "orange":"Orange", "red":"Red", "blue":"Blue", "gray":"Gray", "green":"Green", "dark_leather":"Dark Leather",
                        "dark_texture":"Dark Texture", "gray_lego":"Gray Lego", "green_lego":"Green Lego", "blue_lego":"Blue Lego"
                   ].sort(it?.value)
        }
        section("Default Values") {
            href "pDefaults", title: "Profile Defaults", image: getAppImg("default.png")
        }
        mobileCltTypeSect()
        section ("Debug Options") {
            def sddtfDesc = "This will send all request data to Firebase for troubleshooting and analysis"
            input "sendDebugData", "bool", title: "Send Debug Data to Firebase?", description: sddtfDesc, required: false, defaultValue: false, submitOnChange: true, image: getAppImg("upload.png")
        }
        section ("Security Token", hideable: true, hidden: true) {
            paragraph "Access token:\n${atomicState?.accessToken}\nApplication ID:\n${app.id}"
            href "tokens", title: "Revoke/Reset Security Access Token", description: none
        }
        storageInfoSect()
    }
}

def awsLocaleSection() {
    section("Alexa Skills Region") {
        paragraph title: "Why do we need this?", "This allows us to target the appropriate server for your region"
        input(name: "awsLocale", title:"Please Select your Region", type: "enum", required: true, submitOnChange: true, defaultValue: null, metadata: [values:["US":"US", "UK":"UK"]], image: getAppImg("web.png"))
    }
}

def mobileCltTypeSect() {
    section("Mobile Client") {
        paragraph title: "Why do we need this?", "This allows us to provide you with an experience optimized for your SmartThings Mobile App"
        input(name: "mobileClientType", title:"Primary Mobile Device?", type: "enum", required: true, submitOnChange: true, metadata: [values:["android":"Android", "ios":"Apple iOS"]],
                image: getAppImg("${(settings?.mobileClientType) ? "${settings?.mobileClientType}" : "mobile_device"}.png"))
    }
}

def profConfigPage() {
    def storApp = getStorageApp()
    atomicState?.actionsProcDone = false
    dynamicPage (name: "profConfigPage", title: "", install: false, uninstall: false) {
        def theURL = "https://consigliere-regional.api.smartthings.com/?redirect=" + URLEncoder.encode(getAppEndpointUrl("strooms"))
        // log.trace theURL
        //log.debug "Current State Size: (${getStateSizePerc()}%)"
        def rmData = storApp?.getStateVal("stRoomMap") ?: ""

        section("Potential Issue Detection:") {
            def devProbs = getProblemDevices(settings?.allDevices)
            def isProb = (devProbs?.length() > 1)
            def str = isProb ? devProbs : "No Issues Found"
            paragraph title: isProb ? "Device Names" : "", str, state: (isProb ? null : ""), required: isProb
        }
        if(settings["allDevices"] || settings?.deviceSetupType == "manual") {
            section("Profiles") {
                def profApp = getProfileApps()
                def rDes = profApp?.size() ? "(${profApp?.size()}) Profiles\n\n" : ""
                href "manageProfilesPage", title: "Profile Management", required: false, description: "Tap to Add/Configure/Remove Profiles", state: null, image: getAppImg("es5_rooms.png")
            }
        }
        section("Profile Creation Options:") {
            if(!deviceSetupType) {
                def optDesc = ""
                optDesc += "Automatic (Quickest | For New Users): "
                optDesc += "\nAuto will allow you to pull in the rooms and devices directly from SmartThings and automatically create the profiles"
                optDesc += "\n\nManual (Long Setup Time | Advanced Users):\nManual will require you to select the devices to use for the profile and then manually create each profile on at a time."
                paragraph title: "What are my options?", optDesc
            }
            input "deviceSetupType", "enum", title: "Choose Profile Setup Type", multiple: false, required: true, submitOnChange: true, metadata: [values:["auto":"Automatic", "manual":"Manual"]]
        }
        if(deviceSetupType == "auto") {
            section("Automatic Setup") {
                def lrfshdt = atomicState?.stRoomDataUpdatedDt
                def rDes = "Rooms Available: (${rmData?.size() ?: 0})\n\nLast Updated:\n(${lrfshdt ? prettyDt(lrfshdt) : "Never"})\n\nTap here to ${rmData ? "refresh" : "retrieve"}..."
                href "", title: "Get Rooms from ST Location", url: theURL, style: "embedded", required: false,
                        description: rDes, state: (rmData?.size() ? "complete" : ""), image: getAppImg("rooms2.png")
            }
            section("Manage your Rooms") {
                if(atomicState?.roomDevChgsPending != false) {
                    updateDeviceInputs(rmData, true)
                }
                // input(type: "rooms", name: "addStRooms", title: "Create New ST Rooms(iOS Only)", description: "This allows you to create rooms and assign any unassigned devices", multiple: true, required: false, image: getAppImg("add.png"))
                // input "allDevices", "capability.actuator", multiple: true, title: "All Devices", required: true, submitOnChange: true
                if(rmData?.size()) {
                    input name: "roomsSelForProfCreate", type: "enum", title: "Select the Rooms that Profiles will be Created", multiple: true, required: false, submitOnChange: true,
                        metadata: [values:rmData?.sort { it?.name }.collect { ["${it?.id}":it?.name] }], image: getAppImg("check_list.png")
                }
            }
            def rmSelSize = settings?.roomsSelForProfCreate?.size() ?: 0

            section ("Room Automation Preferences", hideable: true, hidden: (atomicState?.applyProfChgsUpdDt != null)) {
                if(rmSelSize > 0) {
                    input "profileRoomSyncWithST", "bool", title: "Overwrite selected Profile Devices with Devices in ST Rooms?", required: false, defaultValue: false, submitOnChange: true, image: getAppImg("replace.png")
                    if(profileRoomSyncWithST) {
                        input "profileOvrNameWithST", "bool", title: "Overwrite the Profile Name with ST Room Name?", required: false, defaultValue: false, submitOnChange: true, image: getAppImg("replace2.png")
                        input "profileAddNewDevOnly", "bool", title: "Only Add Devices Missing from Existing Room Profiles?", required: false, defaultValue: true, submitOnChange: true, image: getAppImg("add_list.png")
                        if(profileAddNewDevOnly) {
                            paragraph "This will only add new devices and not remove any custom devices added after profile was created...", state: "complete", image: getAppImg("info.png")
                        } else {
                            paragraph title: "Notice:", "This will remove any custom devices added after profile was created...", required: true, state: null, image: getAppImg("info.png")
                        }
                    }
                } else { paragraph "Nothing to Show Until Rooms are Selected..." }
            }
            section("Profile|Room Actions:") {
                def lrfshdt = atomicState?.applyProfChgsUpdDt
                def rDes = lrfshdt ? "Creates/Removes/Updates Profiles based on your Selections.\n\nLast Updated:\n(${prettyDt(lrfshdt)})\n\nTap here to Proceed..." : "Tap here to Proceed..."
                href "processActionsPage", title: "Apply Profile Changes", required: false, description: rDes, state: null, image: getAppImg("finish.png"), params: ["sData":["actType":"profile"]]
            }
        }
        atomicState?.tokenResetActive = false
        storageInfoSect()
        section("Alpha Tools:") {
            input "clearActionMaint", "bool", title: "Clear Profile Maintenance Tasks", required: false, defaultValue: false, submitOnChange: true
            if(settings?.clearActionMaint == true) { clearActionMaint() }
        }
    }
}

def manageProfilesPage() {
    dynamicPage (name: "manageProfilesPage", uninstall: false, install: false) {
        def profApp = findChildAppByName( childProfileName() )
        if(!profApp) { 
            section("") {
                paragraph "NOTE: Looks like you haven't created any Profiles yet.\n\nPlease make sure you have installed the Profiles Add-on before creating a new Profile!"
            }
        }
        section("Profile Apps:") {
            app(name: "profApp", appName: childProfileName(), namespace: childNameSpace(), title: "Create a New Profile", multiple: true, image: getAppImg("es5_rooms.png"))
        }
    }
}

def getProblemDevices(devs) {
    def issueCaps = ["lights", "fans", "outlets", "switches"]
    def rooms = getRoomList()?.collect { it?.name?.toLowerCase() }
    def items = []
    devs?.each { dev->
        def devName = dev?.label?.toString()?.toLowerCase()
        rooms?.each { rm->
            if(devName?.contains(rm)) {
                issueCaps?.each { cap->
                    if(devName?.contains(cap)) {
                        items?.push(devName.split(" ").collect{it.capitalize()}.join(" "))
                    }
                }
            }
        }
    }
    return items?.join(",\n")?.toString().capitalize()
}

def getProfileDeviceList(rmId, idOnly=false) {
    def sApp = getStorageApp()
    def pApps = getProfileApps()
    def rmData = sApp?.getStateVal("stRoomMap") ?: []
    def execTime = now()
    def room = rmData?.find { it?.id == rmId }
    def devs = []
    if(room) {
        if(idOnly) {
            return settings["allDevices"]?.findAll { room?.devices?.collect { it?.id }.contains(it?.id) }.collect { it?.id }
        } else {
            return settings["allDevices"]?.findAll { room?.devices?.collect { it?.id }.contains(it?.id) }
        }
    } else { return [] }
}

def processActionsPage(params){
    def sData = params?.sData
	if(params?.sData) { atomicState.actionMaintPageParams = params }
    else { sData = atomicState?.actionMaintPageParams?.sData }
    dynamicPage(name: "processActionsPage", uninstall: false, install: false, refreshInterval: 8) {
        def actType = sData?.actType
        def actTypeCap = sData?.actType?.toString().capitalize()
        def locale = sData?.locale ?: null
        def itemsToCrt = actType == "profile" ? [] : [:]; List itemsToRem = []; List itemsToUpd = [];
        if(atomicState?.actionsProcDone == null) { atomicState?.actionsProcDone = false }
        try {
            def actRes = atomicState?.actionMaintResults
            if(atomicState?.actionMaintInProg == true) {
                section("${actTypeCap} Maintenance Status") {
                    paragraph title: "${actTypeCap} Maintenance in Progress", "Page will refresh and results will be listed below.\nPlease wait till you see Completed Message before leaving", state: "complete", image: getAppImg("info.png")
                }
                if(actRes?.crtDone?.size()>0) {
                    section("Creation Results") {
                        actRes?.crtDone?.sort()?.unique()?.each { crt-> paragraph title: "${actTypeCap}: (${crt})", "Created Successfully...", state: "complete", image: getAppImg("active.png") }
                    }
                }
                if(actRes?.updDone?.size()>0) {
                    section("Update Results") {
                        actRes?.updDone?.sort()?.unique()?.each { upd-> paragraph title: "${actTypeCap}: (${upd})", "Updated Successfully..." }
                    }
                }
                if(actRes?.remDone?.size()>0) {
                    section("Removal Results") {
                        actRes?.remDone?.sort()?.unique()?.each { rem-> paragraph title: "${actTypeCap}: (${rem})", "Removed Successfully...", state: "complete", image: getAppImg("active.png") }
                    }
                }
            } else if(atomicState?.actionsProcDone == true) {
                section ("") { 
                    paragraph title: "${actTypeCap} Maintenance is Complete...", ""
                    if(!actRes?.remDone?.size() && !actRes?.crtDone?.size() && !actRes?.updDone?.size()) { paragraph title: "Everything is Good.  There was Nothing to do.", "", state: "complete", image: getAppImg("ok_circle.png") }
                    if(actRes?.remDone?.size()) { paragraph title: "Removed (${actRes?.remDone?.unique()?.size()}) ${actTypeCap}s", "", state: "complete", image: getAppImg("ok_circle.png") }
                    if(actRes?.crtDone?.size()) { paragraph title: "Created (${actRes?.crtDone?.unique()?.size()}) ${actTypeCap}s", "", state: "complete", image: getAppImg("ok_circle.png") }
                    if(actRes?.updDone?.size()) { paragraph title: "Updated (${actRes?.updDone?.unique()?.size()}) ${actTypeCap}s", "", state: "complete", image: getAppImg("ok_circle.png") }
                    paragraph "Press Done/Save to go back...", state: "complete"
                }
            } else {
                List skpd = []; List uptd = []; List crtd = []; List rmvd = [];
                if(actType == "skill") {
                    def skillData = atomicState?.skillVendorData ?: [:]
                    skillData?.each { sd->
                        def sName = sd?.nameByLocale[locale] as String
                        if(getSelectedSkills(true, true)?.find { sName == it } == null) {
                            rmvd?.push(sName)
                            itemsToRem?.push(sd?.skillId)
                            // log.warn "Un-Selected Skill Marked for Removal: (${sName})"
                            skillData -= sd
                        }
                    }
                    getSelectedSkills(false, true)?.each { selSkill ->
                        def skName = "EchoSistant5 - ${selSkill}"
                        def skCnt = 1
                        def existingSkillName = skillData?.findAll { it?.nameByLocale[locale]?.toString() == skName }
                        if(existingSkillName?.size()>0) {
                            existingSkillName?.each { prof ->
                                if(skCnt>1) {
                                    itemsToRem?.push(prof?.skillId)
                                    if(skCnt > 1) {
                                        // log.warn "Duplicate Skill Marked for Removal: ${prof?.skillId} - #${skCnt}"
                                        rmvd.push("Duplicate ${prof?.nameByLocale[locale]} - #${skCnt}")
                                    }
                                } else {
                                    //itemsToUpd?.push("${selSkill}:${prof?.skillId}")
                                    //uptd?.push(skName)
                                }
                                skCnt = skCnt+1
                            }
                        } else {
                            itemsToCrt << ["$selSkill":[lambUrn: sData?.lambUrn, vendId: sData?.vendId]]
                            crtd?.push(skName)
                        }
                    }
                }
                else if (actType == "profile") {
                    def sApp = getStorageApp()
                    def rmData = sApp?.getStateVal("stRoomMap") ?: []
                    def pApps = getProfileApps()
                    def selctdRms = settings?.roomsSelForProfCreate.collect { it }
                    selctdRms?.each { selRm ->
                        def roomData = rmData.find { selRm == it?.id }
                        if(roomData) {
                            def rmId = roomData?.id as String
                            def rmName = roomData?.name as String
                            def roomCnt = 1
                            def rmProfs = pApps?.findAll { it?.getRoomId() == rmId }
                            if(rmProfs?.size()>0) {
                                rmProfs?.each { prof ->
                                    def profRmId = prof?.getRoomId() as String
                                    if(roomCnt>1) {
                                        itemsToRem?.push(prof?.id)
                                        if(roomCnt > 1) {
                                            // log.warn "Duplicate Profile Marked for Removal: ${prof?.id} - #${roomCnt}"
                                            rmvd.push("Duplicate ${rmName} - #${roomCnt}")
                                        }
                                    } else {
                                        if(settings?.profileRoomSyncWithST) {
                                            itemsToUpd?.push(prof?.id)
                                            uptd?.push(rmName)
                                        } else { skpd.push(rmName) }
                                    }
                                    roomCnt = roomCnt+1
                                }
                            } else {
                                itemsToCrt << [roomData:roomData]
                                crtd?.push(rmName)
                            }
                        }
                    }
                    def remove = pApps?.findAll { !(it?.getRoomId() in selctdRms) }
                    remove?.each { rm ->
                        itemsToRem?.push(rm?.id)
                        rmvd.push(rm?.getRoomName())
                        // log.warn "Unselected Profile ${rm?.label} Marked for Removal"
                    }
                }
                section(""){
                    def additDesc = actType == "skill" ? "This process will take about 10 sec. per skill" : "This process will take about 20-60 Seconds..."
                    paragraph title: "NOTICE!!!\nPlease remain on this page until this changes to say it's completed.", "The changes listed below have not happened yet.\n${additDesc}", required: true, state: null
                }
                if(rmvd?.size()>0) { section("Removing ${actTypeCap}s:") { paragraph title: "(${rmvd?.size()}) ${actTypeCap}s Scheduled for Removal", "", state: "complete" } }
                if(crtd?.size()>0) { section("Creating ${actTypeCap}s:") { paragraph title: "(${crtd?.size()}) ${actTypeCap}s Scheduled for Creation", "", state: "complete" } }
                if(uptd?.size()>0) { section("Updating ${actTypeCap}s:") { paragraph title: "(${uptd?.size()}) ${actTypeCap}s Scheduled for Update", "", state: "complete" } }
                if(skpd?.size()>0) { section("Skipped ${actTypeCap}s:") { paragraph title: "Skipping (${skpd?.size()}) ${actTypeCap}s", "", state: "complete" } }

                atomicState?.actionsProcDone = true
                if(actType == "skill") { atomicState?.applySkillChgsUpdDt = getDtNow() }
                if(actType == "profile") { atomicState?.applyProfChgsUpdDt = getDtNow() }
                //This will determine which tasks need to be performed on the action type (profile/skill)
                atomicState?.actionMaintResults = [:]
                def am = atomicState?.actionMaintItems ?: [:]
                if(itemsToCrt?.size()) { am["crt"] = itemsToCrt }
                if(itemsToRem?.size()) { am["rem"] = itemsToRem?.unique() }
                if(itemsToUpd?.size()) { am["upd"] = itemsToUpd }
                atomicState?.actionMaintItems = am
                runIn(4, "actionMaintCheck", [overwrite: true, data:["addPass":false, "actType":actType]])
            }
        } catch (ex) {
            log.error "processActionsPage error: ${ex.message}"
        }
    }
}

def clearActionMaint() {
    settingRemove("clearActionMaint")
    atomicState?.actionMaintInProg = null
    atomicState?.actionMaintPassCnt = null
    atomicState?.actionMaintStartDt = null
    atomicState?.actionMaintItems = null
    atomicState?.actionMaintResults = null
    atomicState?.appMaintInProg = false
    atomicState?.profClnRoomNames = null
}

void actionMaintCheck(data) {
    def actType = data?.actType
    def actItems = atomicState?.actionMaintItems
    def addPass = (data?.addPass == true)
    def actTypeCap = data?.actType?.toString().capitalize()
    if(!actItems?.crt?.size() && !actItems?.rem?.size() && !actItems?.upd?.size()) {
        atomicState?.actionMaintInProg = false
        def strtDt = atomicState?.actionMaintStartDt ?: now()
        def passCnt = atomicState?.actionMaintPassCnt
        if(atomicState?.skillRemovalInProg) { 
            atomicState?.skillVendorData = null 
            atomicState?.skillRemovalInProg = false
        }
        LogAction("${actTypeCap} Maintenance Finished | Process Took (${passCnt ?: 1} Pass${passCnt>1 ? "es" : ""}) and (${((now()-strtDt)/1000).toDouble().round(2)}sec) to Complete", "info",true)
        atomicState?.actionMaintStartDt = null
        atomicState?.actionMaintPassCnt = 0
        schedLambdaStatusUpd(30, " | (Profile Maintenance)", true)
    } else {
        if(actType == "skill" && atomicState?.actionMaintPassCnt > 50) { 
            atomicState?.actionMaintInProg = false
            return
        }
        atomicState.actionMaintInProg = true
        if(actType == "profile") { 
            atomicState?.appMaintInProg = true
            lambaDevStateUpdReq(false) 
            unschedule("sendLambdaStatusUpdate")
        }
        if(addPass != true) {
            atomicState?.actionMaintPassCnt = 1
            atomicState?.actionMaintStartDt = now()
        }
        else { atomicState?.actionMaintPassCnt = atomicState?.actionMaintPassCnt + 1 }
        def passCnt = atomicState?.actionMaintPassCnt
        LogAction("actionMaintCheck: (Action: ${actType} | InProg: ${atomicState?.actionMaintInProg}) | FollowUpPass: (${addPass ? "Pass#: ${passCnt}" : "No"}) | Remove: (${actItems?.rem?.size() ?: 0}) | Update: (${actItems?.upd?.size() ?: 0}) | Create: (${actItems?.crt?.size() ?: 0})","debug", true)
        def passDesc = addPass ? "Continuing" : "Starting"
        if(actType == "profile") {
            if(actItems?.rem?.size() || actItems?.upd?.size()) {
                LogAction("${passDesc} Profile Maint Remove/Update (Pass: ${passCnt}) | Pending Removal: (${actItems?.rem?.size() ?: 0}) | Pending Update: (${actItems?.upd?.size() ?: 0})","trace", true)
                runIn(4, "remOrUpdProfiles", [overwrite: true, data:[actType: actType]])
            } else {
                if(actItems?.crt?.size()) {
                    LogAction("${passDesc} Profile Maint Create (Pass: ${passCnt}) | Pending Creation: (${actItems?.crt?.size() ?: 0})","trace", true)
                    runIn(4, "createProfiles", [overwrite: true, data:[actType: actType]])
                }
            }
        } else { 
            if(actItems?.rem?.size()) {
                LogAction("${passDesc} Skill Removal (Pass: ${passCnt}) | Pending Removal: (${actItems?.rem?.size() ?: 0})","trace", true)
                runIn(2, "procSkillRemoval", [overwrite: true, data:[actType: actType]])
            } else if(actItems?.crt?.size()) {
                LogAction("${passDesc} Skill Creation (Pass: ${passCnt}) | Pending Creation: (${actItems?.crt?.size() ?: 0})","trace", true)
                runIn(2, "procSkillCreate", [overwrite: true, data:[actType: actType]])
            } else if(actItems?.upd?.size()) {
                LogAction("${passDesc} Skill Update (Pass: ${passCnt}) | Pending Update: (${actItems?.upd?.size() ?: 0})","trace", true)
                runIn(2, "procSkillUpdate", [overwrite: true, data:[actType: actType]])
            }
        }
    }
}

def maxObjPerPass() { return 10 }

void createProfiles(data) {
    def profs = atomicState?.actionMaintItems
    def maintRes = atomicState?.actionMaintResults ?: [:]
    List remCrt = []
    try {
        if(profs?.crt?.size()) {
            // log.trace "profs: ${profs?.crt?.size()}"
            def cnt = 1
            profs?.crt?.each { crt ->
                if(cnt<=maxObjPerPass()) {
                    def execTime = now()
                    def rmData = crt?.roomData
                    if(rmData) {
                        def rmId = rmData?.id
                        def rmName = rmData?.name
                        def profLbl = "ES-Room | ${rmData?.name}"
                        def setData = [:]
                        setData["roomId"] = [type:"text", value:rmId]
                        setData["roomName"] = [type:"text", value:rmName?.toString()]
                        setData["clnRoomName"] = [type:"text", value:rmName?.toString().replaceAll(" ", "")]
                        setData["autoCreated"] = [type:"bool", value:true]
                        setData["childTypeFlag"] = [type:"text", value:"roomProfile"]
                        setData["allDevices"] = [type:"capability.actuator", value:"null"]
                        def rmDevs = settings["allDevices"]?.findAll { rmData?.devices?.collect { it?.id }.contains(it?.id) }
                        def items = getDeviceCapabList(rmDevs)
                        if(rmDevs?.size()>0 && items) {
                            items?.each { item ->
                                def ign = ["configuration", "refresh", "healthCheck", "indicator", "polling", "outlet", "audioNotification", "lockCodes", "speechSynthesis", "tone" ]
                                def capab = convCapabNameToInputStr(item)
                                if(ign?.contains(capab?.toString())) { return }
                                def capDevs = rmDevs?.findAll { it?.capabilities?.collect { it as String }.contains(item) }.collect {it?.id}
                                setData["dev:${capab}"] = [type:"capability.${capab}", value:capDevs]
                            }
                        }
                        if(setData) {
                            addChildApp(childNameSpace(), childProfileName(), profLbl, [settings:setData])
                            if(!maintRes?.crtDone) { maintRes["crtDone"] = [] }
                            maintRes?.crtDone.push(profLbl)
                            atomicState?.actionMaintResults = maintRes
                            remCrt?.push(crt)
                            LogAction("Profile (${rmData?.name}) Created in (${(now()-execTime)/1000}sec)","trace",true)
                        }
                    } else { LogAction("createProfiles issue, Missing roomData: ${rmData}","error",true) }
                    cnt = cnt+1
                }
            }
        }
    } catch (ex) {
        log.error "createProfiles Exception:", ex
    }
    remCrt?.each { r-> profs?.crt?.remove(r) }
    atomicState?.actionMaintItems = profs
    atomicState?.actionMaintResults = maintRes
    runIn(4, "actionMaintCheck", [overwrite: true, data:[addPass:true, actType: data?.actType]])
}

void remOrUpdProfiles(data) {
    def profs = atomicState?.actionMaintItems
    def maintRes = atomicState?.actionMaintResults ?: [:]
    List remRem = []
    List updRem = []
    try {
        if(!profs?.rem?.size() && !profs?.upd?.size()) {
            runIn(4, "actionMaintCheck", [overwrite: true, data:[addPass:false, actType: data?.actType]])
            return
        }
        def cnt =  1
        getProfileApps()?.each { ca->
            if(cnt<=maxObjPerPass()) {
                if(profs?.rem?.size() && (ca?.id in profs?.rem)) {
                    deleteChildApp(ca)
                    remRem?.push(ca?.id)
                    if(!maintRes?.remDone) { maintRes["remDone"] = [] }
                    maintRes?.remDone.push(ca?.label)
                    // LogAction("Removed Profile: (${ca?.label})", "warn", true)
                    cnt = cnt+1
                }
                if(!prof?.rem?.size() && profs?.upd?.size() && (ca?.id in profs?.upd)) {
                    ca?.devChgFlag()
                    ca?.update()
                    updRem?.push(ca?.id)
                    if(!maintRes?.updDone) { maintRes["updDone"] = [] }
                    maintRes?.updDone.push(ca?.label)
                    // LogAction("Updated Profile: (${ca?.label})", "trace", true)
                    cnt = cnt+1
                }
                atomicState?.actionMaintResults = maintRes
            }
        }
    } catch (ex) {
        log.error "There was an error updating/removing profiles:", ex
    }
    remRem?.each { r-> profs?.rem?.remove(r) }
    updRem?.each { u-> profs?.upd?.remove(u) }
    atomicState?.actionMaintItems = profs
    atomicState?.actionMaintResults = maintRes
    runIn(4, "actionMaintCheck", [overwrite: true, data:[addPass:true, actType: data?.actType]])
}

/*********************************************************************************
                        LAMBDA/STACK MANAGEMENT FUNCTIONS
**********************************************************************************/

def awsStackConfigPage(){
    dynamicPage(name: "awsStackConfigPage", uninstall: false, install: false) {
        def lamData = atomicState?.lambdaData
        if(lamData?.awsAccessKey && lamData?.awsAccessKeySecret) {
            section("Auto Create AWS Stack") {
                def rDes = ""
                if(lamData) {
                    rDes += "\bStack Info:"
                    rDes += "\n • Stack Version: (${lamData?.stackVersion != null ? lamData?.stackVersion : "N/A"})"
                    rDes += lamData?.version != null ? "\n • Lambda Version: (V${lamData?.version})" : ""
                    rDes += lamData?.versionDt != null ? "\n • Lambda Date: (${lamData?.versionDt})" : ""
                    rDes += lamData?.dt ? "\n\nLast Updated:\n(${prettyDt(lamData?.dt)})" : ""
                }
                if(!lamData?.ARN) {
                    def t = "Tap to Install the AWS Stack"
                    paragraph title: "Installation Step 2:", "This automated step will install the full lambda for you.\nJust sit back and relax."
                    href url: getAppEndpointUrl("awsutil"), title: t, description: rDes, state: "complete", image: getAppImg("es5_setup.png")
                } else {
                    paragraph title: "Your All Set!", rDes, state: "complete"
                }
            }
        } else {
            section("Lambda Setup Videos") {
                element(name: "videoElement", element: "video", type: "video", title: "Lambda Setup Video", description: "Lambda Setup Walkthrough", required: false, 
                        image: getAppImg("welcome_lambda.png"), video: "http://f.cl.ly/items/3O2L03471l2K3E3l3K1r/Zombie%20Kid%20Likes%20Turtles.mp4")
            }
            section("Auto Create AWS Stack") {
                def stackURL = getStackInstallUrl() + URLEncoder.encode(getAppEndpointUrl("stackResp"))
                def s1Desc = "This will install a 'Helper' Lambda in AWS for EchoSistant to install automatically."
                s1Desc += "\nWhen you arrive at the next page do the following."
                s1Desc += "\n • Create/Signin to Amazon Developer Account"
                s1Desc += "\n • Scroll down and tap the ckeckbox"
                s1Desc += "\n • Scroll to bottom right and tap 'Create' to install"
                s1Desc += "\n • Wait until your phone notifies you (may take up to 5 min, so be patient)"
                paragraph title: "Installation Step 1:", s1Desc
                href url: stackURL, title: "Begin Install", description: "Tap to proceed", state: "install", image: getAppImg("es5_setup.png")
            }
        }
        section("Alpha Tools:") {	
            input "clearLambdaData", "bool", title: "Clear Lambda Data", required: false, defaultValue: false, submitOnChange: true
            if(settings?.clearLambdaData == true) { clearLambdaData() }
            if(getAwsAccess() && getAwsAccessSecret()) {
                input "deleteAwsStacks", "bool", title: "Remove AWS Stacks", required: false, defaultValue: false, submitOnChange: true
                if(settings?.deleteAwsStacks == true) { deleteAwsStacks() }
            }
        }
        awsLocaleSection()
    }
}

def clearLambdaData() {
    settingRemove("clearLambdaData")
    atomicState?.lambdaData = null
}

def deleteAwsStacks() {
    settingRemove("deleteAwsStacks")
    awsStackAction("DeleteStack", "EchoSistantV5", "awsV5StackDelete")
    runIn(120, "awsStackAction", [overwrite: true, data: [stackAction: "DeleteStack", stackName: "EchoSistantHelper", actType: "awsHelperStackDelete"]])
}

/*********************************************************************************
                    ALEXA SKILL MANAGEMENT FUNCTIONS - START
**********************************************************************************/

def getAlexaAppSkillUrl(id) { return settings?.mobileClientType == "android" ? "https://alexa.amazon.com/?fragment=skills/beta/${id}" : "alexa://alexa?fragment=skills/beta/${id}"}

def awsSkillConfigPage(){
    atomicState?.actionsProcDone = false
    dynamicPage(name: "awsSkillConfigPage", uninstall: false, install: false) {
        def locale = getSkillLocale()
        if(!locale) { 
            awsLocaleSection() 
        } else {
            if(atomicState?.skillAuthData == null) {
                section("Skill Setup Videos") {
                    element(name: "videoElement", element: "video", type: "video", title: "Skill Setup Video", description: "Brief Walkthrough", required: false, 
                            image: getAppImg("welcome_skill.png"), video: getAppVideo("skill_setup1.mp4"))
                }
                section("Get Skill Management Token") {
                    href url: awsSkillAuthUrl(), title: "Get Code Used to Generate Tokens", description: "On the next page enter your amazon credentials and when the code is returned copy/paste into the input below."
                    input "skillTokenCode", "text", title: "Enter the Code Received", required: false, submitOnChange: true
                    href "awsSkillAuthGenPage", title: "Convert Code to Auth Token", hideWhenEmpty: !settings?.skillTokenCode, required: false, description: "This will generate the Auth Token to manage skills"
                }
            } else {
                def token = getSkillToken()
                if(token) {
                    def tokenData = getSkillTokenData()
                    def str = ""
                    str += "Language: (${getSkillLocale()})"
                    str += "\nStatus: (${tokenData?.exp ? "Valid" : "Invalid"})"
                    str += " | Expires: (${tokenData?.exp} sec)"
                    section ("") { paragraph title: "Skill Security Token", str }
                    if(!settings?.mobileClientType) { 
                        mobileCltTypeSect()
                    } else { 
                        def vendors = getSkillVendors()
                        // log.debug "vendors: $vendors"
                        if(vendors?.size()) {
                            def vendId = vendors?.vendors?.find { it?.roles?.contains("ROLE_ADMINISTRATOR") }?.id ?: null
                            if(vendId) {
                                atomicState?.skillVendorId = vendId
                                def skillVendorData = getSkillVendorById(vendId)?.skills?.findAll { it?.nameByLocale?."${locale}"?.startsWith("EchoSistant5 - ") }
                                atomicState?.skillVendorData = skillVendorData
                                def mainSkill = skillVendorData?.find { it?.nameByLocale[locale]?.toString() == "EchoSistant5 - ${settings?.defaultInvocation}" }
                                def hereSkill = skillVendorData?.find { it?.nameByLocale[locale]?.toString() == "EchoSistant5 - Here" }
                                if(!mainSkill || !hereSkill) { 
                                    section("Skills Configured") { 
                                        def mstr = ""
                                        mstr += !mainSkill ? "${mstr != "" ? "\n" : ""} • Main Skill (Missing)" : ""
                                        mstr += !hereSkill ? "${mstr != "" ? "\n" : ""} • Here Skill (Missing)" : ""
                                        paragraph title: "Manditory Skill(s) Missing", "${mstr}\n\nPress Apply/Process Skills to have them Created", required: true, state: null
                                    }
                                }
                                if(skillVendorData?.size()) {    
                                    section("Skills Configured") {
                                        paragraph title: "NOTICE", "Skills Are NOT Enabled by default\nPlease click on a Skill below to Open under the Alexa Mobile App where you can enable it.", required: true, state: null
                                        skillVendorData?.each { sk-> 
                                            def sDesc = ""
                                            sDesc += "Invocation: ${getSkillInvoc(sk?.nameByLocale[locale])}"
                                            sDesc += "\n\nLast Modified:\n${prettyDt(sk?.lastUpdated, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")}"
                                            sDesc += "\n\nTap to Open Skill in Alexa App"
                                            href url: getAlexaAppSkillUrl(sk?.skillId), style:"external", title: "${sk?.nameByLocale[locale]}", description: sDesc
                                        }
                                    }
                                }
                                section("Custom Skills") {
                                    input "skillProfilesSelected", "enum", title: "Create Skills for these Profiles (Optional)", multiple: true, required: false, submitOnChange: true, options: getAllProfileNames(true), image: getAppImg("check_list.png")
                                }
                                section("Apply Changes") {
                                    def lrfshdt = atomicState?.applySkillChgsUpdDt
                                    def rDes = lrfshdt ? "Last Updated:\n(${prettyDt(lrfshdt)})\n\nTap here to Proceed..." : "Tap here to Proceed..."
                                    paragraph title: "What does this do?", "This does the following:\n • Creates Manditory Skills\n • Adds/Removes Custom Skills You Selected"
                                    href "processActionsPage", title: "Apply/Process Skill Changes", required: false, description: rDes, state: (lrfshdt ? "complete": null), image: getAppImg("finish.png"),
                                            params: [sData:[lambUrn:atomicState?.lambdaData?.ARN, vendId:vendId, locale:locale, actType:"skill"]]                                    
                                }
                                // section("") {
                                //     element(name: "videoElement", element: "video", type: "video", title: "Skill Enable Video", description: "Enabling Skill Walkthrough", required: false, 
                                //             image: getAppImg("enable_skills.png"), video: getAppVideo("skill_enable1.mp4"))
                                //             log.debug "${getAppVideo("skill_enable1.mp4")}"
                                // }
                                
                            } else { section("") { paragraph title: "Skill Data Issue", "Unable to find a Valid VendorID", required: true, state: null } }
                        }
                    }
                } else { section ("") { paragraph  title: "Skill Token Issue", "Token Missing/Invalid", required: true, state: null } }
            }
            section("Alpha Tools:") {
                input "clearActionMaint", "bool", title: "Clear Skill Maintenance Tasks", required: false, defaultValue: false, submitOnChange: true
                if(settings?.clearActionMaint == true) { clearActionMaint() }
                input "clearSkillAuth", "bool", title: "Clear Skill Token Data", required: false, defaultValue: false, submitOnChange: true
                if(settings?.clearSkillAuth == true) { clearSkillAuth() }
                input "clearAllSkills", "bool", title: "Remove All Skills", required: false, defaultValue: false, submitOnChange: true
                if(settings?.clearAllSkills == true) { clearAllSkills() }
            }
        }
    }
}

def clearSkillAuth() {
    settingRemove("clearSkillAuth")
    atomicState?.skillAuthData = null
    atomicState?.skillVendorData = null
    atomicState?.skillVendorId = null
}

def clearAllSkills() {
    settingRemove("clearAllSkills")
    def sData = atomicState?.skillVendorData
    def sm = [:]
    List itemsToRem = []
    if(sData?.size()>0) {
        sData?.each { sk -> itemsToRem?.push(sk?.skillId) }
        sm["rem"] = itemsToRem
    }
    atomicState?.actionMaintItems = sm
    atomicState?.skillRemovalInProg = true
    runIn(2, "actionMaintCheck", [overwrite: true, data:[addPass:false, actType:"skill", clearSkills: true]])
}

def getAllProfileNames(cln=false) {
    def items = atomicState?."${cln ? "profClnRoomNames" : "profRoomNames"}" ?: []
    if(!atomicState?."${cln ? "profClnRoomNames" : "profRoomNames"}" || !items?.size()) {
        items = getProfileApps()?.collect { it?.getRoomName(cln) }
        atomicState?."${cln ? "profClnRoomNames" : "profRoomNames"}" = items
    }
    return items?.sort()
}

def awsSkillAuthGenPage() {
    def result = true
    if(!atomicState?.skillAuthData) { result = getTokenFromCode(settings?.skillTokenCode) }
    dynamicPage(name: "awsSkillAuthGenPage", title: "", refreshInterval: (!atomicState?.skillAuthData ? null : null), uninstall: false, install: false){
        section ("Auth Process") {
            if(atomicState?.skillAuthData) {
                paragraph "Token Aquired Successfully...", state: "complete"
            } else {
                paragraph "There was an issue getting the Auth Data", required: true, state: null
            }
        }
    }
}

def getTokenFromCode(code, refresh=false) {
    log.trace "getTokenFromCode(code: $code, refresh: $refresh)"
    if(refresh) { log.debug "Current Skill Token Expired... Attempting to Refresh it..." }
    def bodyItems = [
        grant_type: "authorization_code",
        client_id: "amzn1.application-oa2-client.aad322b5faab44b980c8f87f94fbac56",
        client_secret: "1642d8869b829dda3311d6c6539f3ead55192e3fc767b9071c888e60ef151cf9",
        scope: "alexa::ask:skills:readwrite alexa::ask:models:readwrite alexa::ask:skills:test",
        code: "${code}",
        redirect_uri: "https://s3.amazonaws.com/ask-cli/response_parser.html",
        state: "Ask-SkillModel-ReadWrite"
    ]
    if(refresh && atomicState?.skillAuthData?.refresh_token) {
        bodyItems["grant_type"] = "refresh_token"
        bodyItems["refresh_token"] = atomicState?.skillAuthData?.refresh_token
    }
    def reqParams = [
        uri: "https://api.amazon.com/auth/O2/token",
        contentType: "application/x-www-form-urlencoded",
        autherization: "Basic YW16bjEuYXBwbGljYXRpb24tb2EyLWNsaWVudC5hYWQzMjJiNWZhYWI0NGI5ODBjOGY4N2Y5NGZiYWM1NjoxNjQyZDg4NjliODI5ZGRhMzMxMWQ2YzY1MzlmM2VhZDU1MTkyZTNmYzc2N2I5MDcxYzg4OGU2MGVmMTUxY2Y5",
        accept: "application/json",
        userAgent:"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36",
        body: toQueryString(bodyItems, false)
    ]
    def respData = makeSkillRequests(reqParams, "httpPost", "getTokenFromCode", false)
    if(respData) {
        def authData = [:]
        respData?.each { item -> authData = parseJson(item?.toString()) }
        if(authData && authData != [:]) {
            authData["token_modified_dt"] = getDtNow()
            atomicState?.skillAuthData = authData
            settingRemove("skillTokenCode")
            return true
        }
    }
    return false
}

def getSkillToken() {
    if(atomicState?.skillAuthData?.access_token && atomicState?.skillAuthData?.refresh_token) {
        def tokenData = getSkillTokenData()
        Integer expSec = tokenData?.exp ?: 3601
        if(expSec >= 3600) { getTokenFromCode(settings?.skillTokenCode, true) }
        return atomicState?.skillAuthData?.access_token
    } 
    log.warn "Skill Auth Data Missing..."
    return null
}

def getSkillTokenData() {
    def params = [ uri: "https://api.amazon.com/auth/O2/tokeninfo", query: [ access_token: atomicState?.skillAuthData?.access_token ] ]
    return makeSkillRequests(params, "httpGet", "getSkillTokenData", false)
}

def getSkillVendors() {
    def params = [ uri: "https://api.amazonalexa.com/v0/vendors", headers: [authorization: atomicState?.skillAuthData?.access_token ] ]
    return makeSkillRequests(params, "httpGet", "getSkillVendors", false)
}

def getSkillVendorById(id) {
    def params = [ uri: "https://api.amazonalexa.com/v0/skills?vendorId=${id}&maxResults=50", headers: [authorization: atomicState?.skillAuthData?.access_token ], contentType: "application/json" ]
    return id ? makeSkillRequests(params, "httpGet", "getSkillVendorById", false) : null
}

def createSkill(skillName, urn, vendId) {
    def params = [ uri: "https://api.amazonalexa.com/v0/skills", headers: [authorization: atomicState?.skillAuthData?.access_token ], contentType: "application/json", accept: "application/json", body: generateSkillManifest(skillName, vendId, urn) ]
    return makeSkillRequests(params, "httpPostJson", "createSkill", true)
}

def removeSkill(skillId) {
    def params = [ uri: "https://api.amazonalexa.com/v0/skills/${skillId}", headers: [authorization: atomicState?.skillAuthData?.access_token ], contentType: "application/json", accept: "application/json" ]
    def resp = makeSkillRequests(params, "httpDelete", "removeSkill", true)
    // log.debug "message: ${resp?.message}"
    // log.debug "violations: ${resp?.violations}"
    // log.debug "resp: $resp | ${((!resp?.violations && resp == null) || resp == "" || (resp?.message?.equals("Resource not found.")))}"
    if((!resp?.violations && resp == null) || resp == "" || (resp?.message?.equals("Resource not found."))) { return true }
    return false
}

def updateSkillModel(skillName, skillId) {
    def params = [
        uri: "https://api.amazonalexa.com/v0/skills/${skillId}/interactionModel/locales/${getSkillLocale()}", headers: [authorization: atomicState?.skillAuthData?.access_token ], contentType: "application/json", accept: "application/json",
        body: generateSkillModelJson(skillName)
    ]
    def resp = makeSkillRequests(params, "httpPostJson", "updateSkillModel", true)
    if( (!resp?.violations && resp == null) || resp == [:] || (resp?.violations && resp?.violations[0] && resp?.violations[0]?.message.toString().contains("OngoingBuild"))) { return true }
    return false
}

def getSkillNameFromDataById(id) {
    def item = atomicState?.skillVendorData?.find { it?.skillId == id } 
    return item ? item?.nameByLocale[getSkillLocale()] : null
}

def getSkillExistsByName(name) {
    return getSkillVendorById(atomicState?.vendorId)?.skills?.find { it?.nameByLocale[locale] == name }
}

def makeSkillRequests(params, reqType, type, logOutput=false) {
    def response = null
    def status = null
    def okStatusRange = 200..204
    try {    
        if(params && type) {
            "${reqType}"(params) { resp ->
                response = resp?.data
                status = resp?.status
            }
            if(logOutput) { log.trace "$type | status: (${status}) | reqType: ($reqType) | resp: ${response}" }
            if(status in okStatusRange && response) { return response }
        }
    } catch (ex) {
        if(ex instanceof groovyx.net.http.HttpResponseException) {
            status = ex?.getStatusCode()
            response = ex?.getResponse()?.data
            if(response?.message?.equals("Token is invalid/expired")) { getTokenFromCode(settings?.skillTokenCode, true) }
            log.error "makeSkillRequests($type) | reqType: $reqType | Status: (${ex?.getStatusCode()}) | ErrorResponse: ${response}"
        } else { log.error "makeSkillRequests($type) | reqType: $reqType | Exception: $ex" }
        return response
    }
}

def generateSkillManifest(skillName, vendorId, lambArn, retJson=true) {
    log.debug "generateSkillManifest | skillName: $skillName | vendId: $vendorId | lambArn: $lambArn | region: ${getSkillLocale()}"
    def exampItems = []
    if(skillName == settings?.defaultInvocation) { 
        exampItems = ["tell the ${skillName} to turn off the lights in the living room", "tell the ${skillName} lock the front door in 5 minutes", "tell the ${skillName} good night"]
    } else if(skillName == "Here") {
        exampItems = ["turn off the lights in ${skillName}", "turn off the fan in ${skillName} in 5 minutes", "good morning in ${skillName} in 30 minutes"]
    } else {
        exampItems = ["turn the ${skillName} lights off ", "turn the lights off in the ${skillName}", "tell the ${skillName} good night"]
    }
    def region = "NA"
    if (getSkillLocale()?.toString() == "en-GB") {
    	region = "EU"
    }
    def manifest = [
        "vendorId": vendorId,
        "skillManifest":[
            "publishingInformation": [
                "locales": [ 
                    "${getSkillLocale()?.toString()}": [ 
                        "summary": "EchoSistant Evolution", 
                        "examplePhrases": exampItems, 
                        "keywords": [ "EchoSistant" ], 
                        "name": "EchoSistant5 - ${skillName?.toString().capitalize()}",
                        "smallIconUri": "https://echosistant.com/es5_content/images/echosistant_v5_108px.png", 
                        "largeIconUri": "https://echosistant.com/es5_content/images/echosistant_v5_512px.png",
                        "description": "EchoSistant"
                    ]
                ],
                "isAvailableWorldwide": true, 
                "testingInstructions": "One App to rule them all", 
                "category": "SMART_HOME", 
                "distributionCountries": ["US", "GB"]
            ],
            "apis": [ "custom": [ "endpoint": [ "uri": lambArn ], "interfaces": [ ["type": "RENDER_TEMPLATE"] ] ] ], 
            "manifestVersion": "1.0",
            "permissions": [ ["name": "alexa::devices:all:address:full:read"], ["name": "alexa::household:lists:read"], ["name": "alexa::household:lists:write"] ],
            "privacyAndCompliance": [ 
                "allowsPurchases": false, 
                "locales": [ 
                    "${getSkillLocale()?.toString()}": [ "privacyPolicyUrl": "http://www.echosistant.com" ]
                ], 
                "isExportCompliant": true, 
                "containsAds": false, 
                "isChildDirected": false, 
                "usesPersonalInfo": true 
            ],
            "events": [
                "endpoint": [ "uri": lambArn ],
                "subscriptions": [
                    ["eventName": "SKILL_ENABLED"],
                    ["eventName": "SKILL_DISABLED"],
                    ["eventName": "SKILL_PERMISSION_ACCEPTED"],
                    ["eventName": "SKILL_PERMISSION_CHANGED"],
                    ["eventName": "SKILL_ACCOUNT_LINKED"]
                ],
                "regions": [
                    "${region}": [
                        "endpoint": ["uri": lambArn]
                    ]
                ]
            ]
        ]
    ]
    // log.debug "manifest: ${manifest?.skillManifest?.publishingInformation?.locales}"
    def json = new JsonOutput().toJson(manifest)
    def res = new JsonOutput().prettyPrint(json)
    return retJson ? res : manifest
}

def generateSkillModelJson(skillName="here", retJson=true) {
    log.debug "generateSkillModelJson skillName: $skillName"
    def appStatus = [ [ "name": "AppStatus", "samples":[ "version info", "app status", "app details", "instance status", "app info" ] ] ]
    def updSettings = [ [ "name": "UpdateSettings", "samples":[ "update settings", "update configuration" ] ] ]
    def intentMap = [
        "interactionModel": [
            "languageModel": [
                "invocationName": "${skillName?.toLowerCase()}",
                "intents":[
                    [ "name": "AMAZON.HelpIntent", "samples": [ "what can i do", "i need help", "i need ideas", "what can i say", "what is this", "give me an idea", "i'm lost" ] ],
                    [ "name": "AMAZON.MoreIntent", "samples": [] ], [ "name": "AMAZON.NavigateHomeIntent", "samples": [] ], [ "name": "AMAZON.NavigateSettingsIntent", "samples": [] ], [ "name": "AMAZON.NextIntent","samples": [] ],
                    [ "name": "AMAZON.NoIntent", "samples": [] ], [ "name": "AMAZON.PageDownIntent", "samples": [] ], [ "name": "AMAZON.PageUpIntent", "samples": [] ], [ "name": "AMAZON.PreviousIntent", "samples": [] ], 
                    [ "name": "AMAZON.ScrollDownIntent", "samples": [] ], [ "name": "AMAZON.ScrollLeftIntent", "samples": [] ], [ "name": "AMAZON.ScrollRightIntent", "samples": [] ], [ "name": "AMAZON.ScrollUpIntent", "samples": [] ],
                    [ "name": "AMAZON.CancelIntent", "samples": [] ], [ "name": "AMAZON.StopIntent", "samples": [] ], [ "name": "AMAZON.YesIntent", "samples": [] ],
                    [ "name": "${skillName?.toString().capitalize()}", "slots": [ [ "name": "ttstext", "type": "CATCH_ALL" ] ], "samples": [ "{ttstext}" ] ]
                ],
                "types":[ [ 
                    "values": [
                        [ "name":[ "value": "turn", "synonyms": [] ] ], [ "name":[ "value": "put to", "synonyms": [] ] ], [ "name":[ "value": "enter are void", "synonyms": [] ] ], [ "name":[ "value": "over around and under", "synonyms": [] ] ],
                        [ "name":[ "value": "light switch fan outlet relay", "synonyms": [] ] ], [ "name":[ "value": "water speaker list media set above", "synonyms": [] ] ], [ "name":[ "value": "on start enable engage open begin unlock unlocked", "synonyms": [] ] ],
                        [ "name":[ "value": "delay wait until after around within in about for", "synonyms": [] ] ], [ "name":[ "value": "darker too bright dim dimmer decrease lower low softer less", "synonyms": [] ] ],
                        [ "name":[ "value": "give is tell what how is when which are how many check who status", "synonyms": [] ] ], [ "name":[ "value": "increase more too dark not bright enough brighten brighter turn up", "synonyms": [] ] ],
                        [ "name":[ "value": "off stop cancel disable disengage kill close silence lock locked quit end", "synonyms": [] ] ], [ "name":[ "value": "door garage window shade curtain blind thermostat indoor outdoor vent valve", "synonyms": [] ] ]
                    ], "name": "CATCH_ALL" ] 
                ]
            ]
        ]
    ]
    if(skillName in ["here", "Here"]) { 
        intentMap?.interactionModel?.languageModel?.intents = intentMap?.interactionModel?.languageModel?.intents + updSettings 
    } else { intentMap?.interactionModel?.languageModel?.intents = intentMap?.interactionModel?.languageModel?.intents + updSettings + appStatus }
    def json = new JsonOutput().toJson(intentMap)
    def res = new JsonOutput().prettyPrint(json)
    // log.debug "intentMap: ${retJson ? res : intentMap}"
    return retJson ? res : intentMap
}

def getTokenExpireDtSec() { return !atomicState?.skillAuthData?.token_modified_dt ? 7200 : GetTimeDiffSeconds(atomicState?.skillAuthData?.token_modified_dt, null, "getTokenExpireDtSec").toInteger() }

def toQueryString(Map m, encode=true) {
	return m.collect { k, v -> "${k}=${encode ? URLEncoder.encode(v.toString()) : v?.toString()}" }.sort().join("&")
}

def manditorySkills(sendFullName=true) {
    return sendFullName ? [convSkillName("${settings?.defaultInvocation}"), convSkillName("Here")] : ["${settings?.defaultInvocation}", "Here"]
}

def convSkillName(name) {
    return "EchoSistant5 - $name"
}

def getSelectedSkills(sendFullName, manditory=true) {
    def sel = []
    sel = sel + (settings?.skillProfilesSelected ? settings?.skillProfilesSelected?.collect { sendFullName ? convSkillName(it) : it } : [])
    if(manditory) { sel = sel + manditorySkills(sendFullName) }
    return sel
}

void procSkillCreate(data) {
    def curItem = null
    def items = atomicState?.actionMaintItems
    def maintRes = atomicState?.actionMaintResults ?: [:]
    // log.debug "procSkillCreate | items: $items"
    Map crtRem = [:]
    try {
        if(!items?.crt?.size()) {
            runIn(2, "actionMaintCheck", [overwrite: true, data:[addPass:false, actType:data?.actType]])
            return
        }
        def cnt = 1
        if(items?.crt?.size()) {
            items?.crt?.each { crtItem ->
                log.debug "crtItem: $crtItem"
                if(cnt<=5) {
                    curItem = crtItem
                    def res = createSkill(crtItem?.key, crtItem?.value?.lambUrn, crtItem?.value?.vendId)
                    if(res?.skillId) { 
                        if(updateSkillModel(crtItem?.key, res?.skillId)) {
                            // LogAction("Skill (${crtItem?.key})", "trace", true)
                            crtRem << crtItem
                            if(!maintRes?.crtDone) { maintRes["crtDone"] = [] }
                            maintRes?.crtDone.push("EchoSistant5 - ${crtItem?.key}")
                            atomicState?.actionMaintResults = maintRes
                        }
                    } else { LogAction("procSkillCreate issue, Missing skillData: ${crtItem}","error",true) }
                    cnt = cnt+1
                }
            }
        }
    } catch (ex) { 
        if(ex instanceof java.util.ConcurrentModificationException) {
            // log.debug "Skill is Currently being Created"
            //if(curItem) { items?.upd.remove(curItem) }
        } else { log.error "procSkillCreate Exception:", ex }
    }
    crtRem?.each { c-> items?.crt?.remove(c?.key) }
    atomicState?.actionMaintItems = items
    atomicState?.actionMaintResults = maintRes
    runIn(2, "actionMaintCheck", [overwrite: true, data:[addPass:true, actType:data?.actType]])
}

void procSkillUpdate(data) {
    def curItem = null
    def items = atomicState?.actionMaintItems
    def maintRes = atomicState?.actionMaintResults ?: [:]
    List updRem = []
    try {
        if(!items?.upd?.size()) {
            runIn(2, "actionMaintCheck", [overwrite: true, data:[addPass:false, actType:data?.actType]])
            return
        }
        def cnt = 1
        if(items?.upd?.size()) {
            items?.upd?.each { updItem->
                if(cnt<=5) {
                    curItem = updItem
                    def spl = updItem?.split(":")
                    if(spl[0] && spl[1]) {
                        if(updateSkillModel(spl[0], spl[1])) {
                            // LogAction("Updated Skill: (${spl[0]})", "trace", true) 
                            updRem?.push(updItem)
                            if(!maintRes?.updDone) { maintRes["updDone"] = [] }
                            maintRes?.updDone.push("EchoSistant5 - ${spl[0]}")
                            atomicState?.actionMaintResults = maintRes
                            cnt = cnt+1
                        }
                    }
                }
            }
        }
    } catch (ex) {
        if(ex instanceof java.util.ConcurrentModificationException) {
            // log.debug "Skill is Already being built"
            if(curItem) { items?.upd.remove(curItem) }
        } else { log.error "There was an error updating skill:", ex }
    }
    updRem?.each { u-> items?.upd?.remove(u) }
    atomicState?.actionMaintItems = items
    atomicState?.actionMaintResults = maintRes
    runIn(2, "actionMaintCheck", [overwrite: true, data:[addPass:true, actType:data?.actType]])
}

void procSkillRemoval(data) {
    def curItem = null
    def items = atomicState?.actionMaintItems
    def maintRes = atomicState?.actionMaintResults ?: [:]
    List remRem = []
    try {
        if(!items?.rem?.size()) {
            runIn(2, "actionMaintCheck", [overwrite: true, data:[addPass:false, actType:data?.actType]])
            return
        }
        def cnt = 1
        if(items?.rem?.size()) {
            items?.rem?.each { remItem->
                if(cnt<=5) {
                    curItem = remItem
                    def name = getSkillNameFromDataById(remItem)
                    if(removeSkill(remItem)) {
                        // LogAction("Removed Skill: (${name})", "warn", true)
                        remRem?.push(remItem)
                        if(!maintRes?.remDone) { maintRes["remDone"] = [] }
                        maintRes?.remDone.push("EchoSistant5 - ${name}")
                        atomicState?.actionMaintResults = maintRes
                        cnt = cnt+1
                    }
                }
            }
        }
    } catch (ex) {
        if(ex instanceof java.util.ConcurrentModificationException) {
            // log.debug "Skill is Already being removed"
            if(curItem) { items?.rem.remove(curItem) }
        } else {
            log.error "There was an error processing skill removal:", ex
        }
    }
    remRem?.each { r-> items?.rem?.remove(r) }
    atomicState?.actionMaintItems = items
    atomicState?.actionMaintResults = maintRes
    runIn(2, "actionMaintCheck", [overwrite: true, data:[addPass:true, actType:data?.actType]])
}

/*********************************************************************************
                    ALEXA SKILL MANAGEMENT FUNCTIONS - END
**********************************************************************************/

def pDefaults() {
    dynamicPage(name: "pDefaults", title: "", uninstall: false, install: false){
        section ("General Control") {
            input "adjSetLevel", "number", title: "Alexa Adjusts Light Levels by using a scale of 1-10 (default is +/-3)", defaultValue: 3, required: false
            input "adjVolLevel", "number", title: "Alexa Adjusts the Volume Level by using a scale of 1-10 (default is +/-2)", defaultValue: 2, required: false
            input "adjTempVal", "number", title: "Alexa Automatically Adjusts temperature by using a scale of 1-10 (default is +/-1)", defaultValue: 1, required: false
        }
        section ("Fan Control") {
            input "adjFanHigh", "number", title: "Alexa Adjusts High Level to 99% by default", defaultValue: 99, required: false
            input "adjFanMed", "number", title: "Alexa Adjusts Medium Level to 66% by default", defaultValue: 66, required: false
            input "adjFanLow", "number", title: "Alexa Adjusts Low Level to 33% by default", defaultValue: 33, required: false
            input "adjFanLevel", "number", title: "Alexa Automatically Adjusts Ceiling Fans by using a scale of 1-100 (default is +/-33%)", defaultValue: 33, required: false
        }
        section ("Activity Defaults") {
            input "lowBattVal", "number", title: "Alexa Provides Low Battery Feedback when the Bettery Level falls below... (default is 25%)", defaultValue: 25, required: false
            input "inactiveDevVal", "number", title: "Alexa Provides Inactive Device Feedback when No Activity was detected for... (default is 24 hours) ", defaultValue: 24, required: false
        }
    }
}

def helpPage () {
	dynamicPage(name: "helpPage", title: "Help and Troubleshooting", install: false) {
        section ("Directions, How-to's, and Troubleshooting") {
            href url: getWikiPageUrl(), title: "View EchoSistant Wiki", description: none, image: getAppImg("wiki.png")
            href url: getIssuePageUrl(), title: "Report | View Issues", style: "embedded", description: "Tap to open in browser", required: false, state: "complete", image: getAppImg("issue.png")
        }
        showDevSharePrefs()
	}
}

def uninstallPage() {
	dynamicPage(name: "uninstallPage", title: "Uninstall", uninstall: true, install: false, refreshInterval: 10) {
        if(atomicState?.skillRemovalInProg) { 
            section("") {
                paragraph title: "NOTICE", "Skills are being Removed\nThis page will update every 10 seconds", state: "complete"
            }
        }
        section("AWS Stack Removal") {
            if(atomicState?.lambdaData) {
                paragraph "If you are not planning on reinstalling it recommended that your remove these items"
                input "deleteAwsStacks", "bool", title: "Remove AWS Stack", required: false, defaultValue: false, submitOnChange: true
                if(settings?.deleteAwsStacks == true) { deleteAwsStacks() }
            } else {
                paragraph "AWS Stack is Not Installed"
            }
        }
        section("Alexa Skill Removal") {
            if(atomicState?.skillVendorData) {
                paragraph "If you are not planning on reinstalling it recommended that your remove these items"
                input "clearAllSkills", "bool", title: "Remove All Alexa Skills", required: false, defaultValue: false, submitOnChange: true
                if(settings?.clearAllSkills == true) { clearAllSkills() }
            } else { paragraph "No Skills Found" }
        }
		section("") {
			paragraph title: "NOTICE", "There is NO coming back from this!\nThis will uninstall the App, All Profiles and ShortCuts.", required: true, state: null
		}
		remove("Remove ${appName()}!", "WARNING!!!", "Last Chance to Stop!\nThis action is not reversible\n\nThis App, and All Profiles will be removed")
	}
}

def codeUpdatesPage() {
    dynamicPage(name: "codeUpdatesPage", uninstall: false, install: false) {
        def theURL = "https://consigliere-regional.api.smartthings.com/?redirect=" + URLEncoder.encode(getAppEndpointUrl("stupdate"))
        // log.debug theURL
        section() {
            def lamData = atomicState?.lambdaData
            def lDes = "\bStack Info:"
            lDes += "\n • Stack Version: (${lamData?.stackVersion != null ? lamData?.stackVersion : "N/A"})"
            lDes += "\n • Lambda Version: (${lamData?.version != null ? "V${lamData?.version}" : "N/A"})"
            lDes += "\n • Lambda Date: (${lamData?.versionDt != null ? "${lamData?.versionDt}" : "N/A"})"
            lDes += "\n\n\bSmartApps:"
            lDes += "\n • Parent Version: (${releaseVer() ?: "N/A"})"
            lDes += "\n • Profile Module: (${atomicState?.swVer?.profVer != null ? atomicState?.swVer?.profVer : "N/A"})"
            lDes += "\n • Shortcuts Module: (${atomicState?.swVer?.shrtCutVer != null ? atomicState?.swVer?.shrtCutVer : "N/A"})"
            lDes += "\n • Storage Module: (${atomicState?.swVer?.storVer != null ? atomicState?.swVer?.storVer : "N/A"})"
            paragraph lDes, state: "complete"
        }
        section() {
            paragraph title: "What will this do?", "This process makes sure the following are up-to-date:\n • Lambda\n • Skills(Not Yet)\n • All SmartApps\n\nAll you will need to do is sign in to the IDE and watch it go..."
            href url: theURL, title: "Tap to Update", description: null, image: getAppImg("es5_update.png")
        }
        section() {
			href "changeLogPage", title: "View Changelog", description: "", image: getAppImg("new.png")
		}
    }
}

def changeLogPage () {
	dynamicPage(name: "changeLogPage", title: "", nextPage: "mainPage", install: false) {
		section() {
			paragraph title: "What's New in this Release...", "", state: "complete", image: getAppImg("new.png")
			paragraph chgLogInfo()
		}
		def iData = atomicState?.installData
		iData["shownChgLog"] = true
		atomicState?.installData = iData
	}
}

def showDevSharePrefs() {
    def hide = (atomicState?.newSetupComplete == true)
    section("Data Collection: ", hideable: hide, hidden: hide) {
        input ("optInUseAnalytics", "bool", title: "We Need Your Help!", description: "Can we collect Anonymous data about the way you speak to Echosistant?", required: false, defaultValue: false, submitOnChange: true, image: getAppImg("app_analytics.png"))
        def str = "This data will only be used to increase the accuracy of next Echosistant version."
        str += "\nData Collected:\n • Your Requests\n • Responses Given\n • Device Counts\n • Profile Counts\n • Shortcut Counts\n • Local Timezone\n • App Versions"
		paragraph title: "What Data are we Collecting?", str, state: "complete"
        paragraph title: "NOTICE:", "No Audio is ever captured.\n\nAny data collected will never be shared with 3rd-Parties"
	}
}

def tokens() {
    dynamicPage(name: "tokens", title: "Security Tokens", uninstall: false, install: false) {
        def tokenOk = getAccessToken()
        section(""){
            paragraph "Tap below to Reset/Renew the Security Token. You must log in to the IDE and open the Live Logs tab before tapping here. "+
                "Copy and paste the displayed tokens into your Amazon Lambda Code."
            if (!tokenOk) {
                paragraph "You must enable OAuth via the IDE to setup this app", required: true, state: null
            }
        }
        if(tokenOk) {
            section ("SmartThings Access Token Reset"){
                href "tokenResetConfirmPage", title: "Reset Access Token", description: none
            }
        }
    }
}

def tokenResetConfirmPage() {
    dynamicPage(name: "tokenResetConfirmPage", title: "Reset/Renew Access Token Confirmation", uninstall: false, install: false){
        section {
            href "tTokenReset", title: "PLEASE CONFIRM!", description: "Once you reset the access token you will disable all communication between this SmartApp and your Amazon Echo. "+
                "You will need to update the Amazon Lambda code with the new access token to re-enable access. \n\nTap here to Reset/Renew Access Token", required: true, state: null
        }
        section(" "){
            href "mainPage", title: "Cancel And Go Back To Main Menu", description: "Tap here to cancel and go back to the main menu with out resetting the token.\n\nYou may also tap Done above.", state: "complete"
        }
        atomicState?.tokenResetActive = true
    }
}

def tTokenReset() {
    dynamicPage(name: "tTokenReset", title: "Access Token Reset", nextPage: "mainPage", uninstall: false, install: false){
        section("") {
            if(atomicState?.tokenResetActive) {
                atomicState?.oldAccessToken = atomicState?.accessToken
                resetSTAccessToken()
                def msg = atomicState?.accessToken != null ? "New access token:\n${atomicState?.accessToken}\n\n" : "Could not reset Access Token."+
                    "OAuth may not be enabled. Go to the SmartApp IDE settings to enable OAuth."
                paragraph "${msg}"
                paragraph "Your new Access Token and AppID should be displayed in the Live Logs in the IDE."
                LogAction("New Accesstoken = '${atomicState?.accessToken}'","info", true)
            } else {
                paragraph "Your Token has already been reset.  Please return to Home Page"
            }
        }
        section(" "){
            href "mainPage", title: "Tap Here To Go Back To Main Menu", description: none
        }
    }
}

def securityPage() {
	dynamicPage(name: "securityPage", title: "",install: false, uninstall: false) {
		section ("Set Master/Guest PIN Number to Perform Secure Functions") {
        	input "masterSecPIN", "number", title: "Use this PIN for ALL Security/Safety Related Controls", range: "0001..9999", required: false, submitOnChange: true
            input "allowTempPIN", "bool", title: "Enable Guest PIN?\n(Expires in 24 hours)", default: false, submitOnChange: true
            if(settings?.allowTempPIN) { input "tempSecPIN", "number", title: "Guest PIN ", range: "0001..9999", required: false, submitOnChange: true }
    	}
        section ("Custom PIN Security Options") {
            paragraph "Nothing to show here yet"
			// def routines = location.helloHome?.getPhrases()*.label.sort()
        //     input "cMiscDev", "capability.switch", title: "Allow these Switches to be PIN Protected...", multiple: true, required: false, submitOnChange: true
        //     input "cRoutines", "enum", title: "Allow these Routines to be PIN Protected...", options: routines, multiple: true, required: false
        //     input "uPIN_SHM", "bool", title: "Enable PIN for Smart Home Monitor?", default: false, submitOnChange: true
        //     if(uPIN_SHM == true)  {paragraph "You can also say: Alexa enable/disable the pin number for Security"}
        //     	input "uPIN_Mode", "bool", title: "Enable PIN for Location Modes?", default: false, submitOnChange: true
        //     if(uPIN_Mode == true)  {paragraph "You can also say: Alexa enable/disable the pin number for Location Modes"}
		// 	if (cMiscDev) 			{input "uPIN_S", "bool", title: "Enable PIN for Switch(es)?", default: false, submitOnChange: true}
        //    	if(uPIN_S == true)  {paragraph "You can also say: Alexa enable/disable the pin number for Switches"}
        //    	if (cTstat) 			{input "uPIN_T", "bool", title: "Enable PIN for Thermostats?", default: false, submitOnChange: true}
		// 	if(uPIN_T == true)  {paragraph "You can also say: Alexa enable/disable the pin number for Thermostats"}
		// 	if (cDoor || cRelay) 	{input "uPIN_D", "bool", title: "Enable PIN for Doors?", default: false, submitOnChange: true}
		// 	if(uPIN_D == true)  {paragraph "You can also say: Alexa enable/disable the pin number for Doors"}
		// 	if (cLock) 				{input "uPIN_L", "bool", title: "Enable PIN for Locks?", default: false, submitOnChange: true}
		// 	if(uPIN_L == true)  {paragraph "You can also say: Alexa enable/disable the pin number for Locks"}
     	}
	}
}

def storageInfoSect() {
    def storApp = getStorageApp()
    section("Storage App Info:") {
        if(storApp) {
            def str = ""
            str += "Version: V${storApp?.releaseVer()}"
            str += "\nUsage: ${storApp?.getStateSizePerc()}%"
            paragraph str, state: "complete"
        } else {
            paragraph "Error: Storage SmartApp Is Not Installed...", required: true, state: null
        }
    }
}

def notifPrefPage() {
	def execTime = now()
	dynamicPage(name: "notifPrefPage", install: false) {
		def sectDesc = !location.contactBookEnabled ? "Enable push notifications below" : "Select People or Devices to Receive Notifications"
		section(sectDesc) {
			if(!location.contactBookEnabled) {
				input(name: "usePush", type: "bool", title: "Send Push Notitifications", required: false, defaultValue: false, submitOnChange: true, image: getAppImg("es5_notify.png"))
			} else {
				input(name: "recipients", type: "contact", title: "Select Default Contacts", required: false, submitOnChange: true, image: getAppImg("contact_card.png")) {
					input ("phone", "phone", title: "Phone Number to send SMS to", required: false, submitOnChange: true, image: getAppImg("es5_notify.png"))
				}
			}
			if(settings?.recipients || settings?.phone || settings?.usePush) {
				def t1 = getRestrictSchedDesc("notifQuiet")
				href "timeRestrictPage", title: "Notification Restrictions", description: (t1 ?: "Tap to configure"), state: (t1 ? "complete" : null), image: getAppImg("restriction.png"), params: ["sData":["prefix":"notifQuiet"]]
			}
		}
		if(settings?.recipients || settings?.phone || settings?.usePush) {
			if(settings?.recipients && !atomicState?.pushTested) {
				if(sendMsg("Info", "Push Notification Test Successful. Notifications Enabled for ${appName()}", false)) {
					atomicState.pushTested = true
				}
			}
			section("Alert Configurations:") {
				def t1 = getAppNotifDesc()
				def appDesc = t1 ? "${t1}\n\n" : ""
				href "notifConfigPage", title: "App Notifications", description: "${appDesc}Tap to configure", params: [pType:"app"], state: (appDesc != "" ? "complete" : null), image: getAppImg("es5_notify.png")
			}
			section("Reminder Settings:") {
				input name: "notifyMsgWaitVal", type: "enum", title: "Default Reminder Wait?", required: false, defaultValue: 3600,
						metadata: [values:notifValEnum()], submitOnChange: true, image: getAppImg("reminder.png")
			}
		} else { atomicState.pushTested = false }
		atomicState?.notificationPrefs = buildNotifPrefMap()
	}
}

def notifConfigPage(params) {
	def pType = params.pType
	if(params?.pType) {
		atomicState.curNotifConfigPageData = params
	} else {
		pType = atomicState?.curNotifConfigPageData?.pType
	}
	def execTime = now()
	dynamicPage(name: "notifConfigPage", install: false) {
		switch(pType.toString()) {
			case "app":
				section("Code Update Notifications:") {
					paragraph "Receive notifications when App and Device updates are available", state: "complete"
					input name: "sendAppUpdateMsg", type: "bool", title: "Alert on Updates?", defaultValue: true, submitOnChange: true, image: getAppImg("es5_update.png")
					if(settings?.sendAppUpdateMsg == true || settings?.sendAppUpdateMsg == null) {
						input name: "updNotifyWaitVal", type: "enum", title: "Send Update Reminder Every?", required: false, defaultValue: 43200,
								metadata: [values:notifValEnum()], submitOnChange: true, image: getAppImg("reminder.png")
					}
				}
				break
		}
	}
}

def timeRestrictPage(params) {
    def sData = params?.sData
    def prefix
	if(params?.sData) {
		atomicState.tmpRestrictPageData = params
		sData = params?.sData
        prefix = sData?.prefix
	} else {
		sData = atomicState?.tmpRestrictPageData?.sData
        prefix = sData?.prefix
	}
    def desc = "Prevent"
    def titleDesc = ""
    switch(prefix) {
        case "notifQuiet":
            titleDesc = "Silence Notifications During\nthese Days, Times or Modes"
            desc = "Silence Notifications"
            break
        case "quietMode":
            titleDesc = "Enable Quiet Mode During\nthese Days, Times or Modes"
            desc = "Quiet Mode"
            break
        case "reply":
            titleDesc = "Restrict Feedback During\nthese Days, Times or Modes"
            desc = "Feedback Only"
            break
    }
	dynamicPage(name: "timeRestrictPage", title: titleDesc, uninstall: false) {
		def timeReq = (settings["${prefix}StartTime"] || settings["${prefix}StopTime"]) ? true : false
		section() {
			input "${prefix}StartInput", "enum", title: "Starting at", options: ["A specific time", "Sunrise", "Sunset"], defaultValue: null, submitOnChange: true, required: false, image: getAppImg("start_time.png")
			if(settings["${prefix}StartInput"] == "A specific time") {
				input "${prefix}StartTime", "time", title: "Start time", required: timeReq, image: getAppImg("start_time.png")
			}
			input "${prefix}StopInput", "enum", title: "Stopping at", options: ["A specific time", "Sunrise", "Sunset"], defaultValue: null, submitOnChange: true, required: false, image: getAppImg("stop_time.png")
			if(settings?."${prefix}StopInput" == "A specific time") {
				input "${prefix}StopTime", "time", title: "Stop time", required: timeReq, image: getAppImg("stop_time.png")
			}
			input "${prefix}Days", "enum", title: "${desc} on these Days", multiple: true, required: false, image: getAppImg("day_calendar.png"), options: timeDayOfWeekOptions()
			input "${prefix}Modes", "mode", title: "${desc} in these Modes", multiple: true, submitOnChange: true, required: false, image: getAppImg("mode.png")
		}
	}
}

def restrictionTimeOk(prefix, invert=false) {
    def strtTime = null
    def stopTime = null
    def now = new Date()
    def sun = getSunriseAndSunset() // current based on geofence, previously was: def sun = getSunriseAndSunset(zipCode: zipCode)
    if(settings["${prefix}StartTime"] && settings["${prefix}StopTime"]) {
        if(settings["${prefix}StartInput"] == "sunset") { strtTime = sun?.sunset }
        else if(settings["${prefix}StartInput"] == "sunrise") { strtTime = sun.sunrise }
        else if(settings["${prefix}StartInput"] == "A specific time" && settings["${prefix}StartTime"]) { strtTime = settings["${prefix}StartTime"] }

        if(settings["${prefix}StopInput"] == "sunset") { stopTime = sun.sunset }
        else if(settings["${prefix}StopInput"] == "sunrise") { stopTime = sun.sunrise }
        else if(settings["${prefix}StopInput"] == "A specific time" && settings["${prefix}StopTime"]) { stopTime = settings["${prefix}StopTime"] }
    } else { return invert ? false : true }
    if(strtTime && stopTime) {
        return timeOfDayIsBetween(strtTime, stopTime, new Date(), location.timeZone) ? invert ? true : false : invert ? false : true
    } else { return invert ? false : true }
}

void checkQuietMode() {
    def timeOk = !restrictionTimeOk("quietMode") ?: false
    def modeOk = isInMode(settings["quietModeModes"]) ?: false
    def dayOk = !daysOk(settings["quietModeDays"]) ?: false
    def ok = (timeOk || modeOk || dayOk)
    // log.debug "quietMode: ${ok} | timeOk: $timeOk | modeOk: $modeOk | dayOk: $dayOk"
    if(ok) {
        if(settings["quietMode"] == false) { settingUpdate("quietMode", "true", "bool") }
    } else { if (settings["quietMode"] == true) { settingUpdate("quietMode", "false", "bool") } }
}

def useQuietMode() {
    def timeOk = !restrictionTimeOk("quietMode") ?: false
    def modeOk = isInMode(settings["quietModeModes"]) ?: false
    def dayOk = !daysOk(settings["quietModeDays"]) ?: false
    def ok = (timeOk || modeOk || dayOk)
    // log.debug "quietMode: ${ok} | timeOk: $timeOk | modeOk: $modeOk | dayOk: $dayOk"
    if(ok) {
        if(settings["quietMode"] == false) { settingUpdate("quietMode", "true", "bool") }
    } else { if (settings["quietMode"] == true) { settingUpdate("quietMode", "false", "bool") } }
    return ok
}

def getFeedbackType() {
    def fb = settings?.feedbackType as String
    if(fb in ["none", "disable"]) {
        return "none"
    } else if(fb in ["default", "short"]) {
        def timeOk = !restrictionTimeOk("reply", true)
        def modeOk = settings["replyModes"] ? isInMode(settings["replyModes"]) : true
        def dayOk = settings["replyDays"] ? daysOk(settings["replyDays"]) : true
        def ok = (timeOk && modeOk && dayOk)
        // log.debug "feedbackType: ${ok} | timeOk: $timeOk | modeOk: $modeOk | dayOk: $dayOk"
        return ok ? fb : "none"
    } else { return "default" }
}

def getAwsStackDesc() {
	def str = ""
    def sData = atomicState?.lambdaData
    if(sData) {
	    str += sData?.stackVersion ? "${str == "" ? "" : "\n"} • Stack: v${sData?.stackVersion}" : ""
        str += sData?.version ? "${str == "" ? "" : "\n"} • Lambda: v${sData?.version}" : ""
    }
	return str != "" ? str : null
}

def getSkillDesc() {
	def sData = atomicState?.skillVendorData
    def locale = getSkillLocale()
    def str = ""
    if(sData?.size()) {
        def cnt = sData?.size() ?: 0
        def mainSkill = sData?.find { it?.nameByLocale[locale]?.toString() == "EchoSistant5 - ${settings?.defaultInvocation}" } ? true : false
        def hereSkill = sData?.find { it?.nameByLocale[locale]?.toString() == "EchoSistant5 - Here" } ? true : false
        str += mainSkill && hereSkill  ? "${str == "" ? "" : "\n"} • Default Skills: (Good)" : ""
        str += !mainSkill && hereSkill  ? "${str == "" ? "" : "\n"} • Main Skill: (Missing)" : ""
        str += mainSkill && !hereSkill ? "${str == "" ? "" : "\n"} • Here Skill: (Missing)" : ""
        def customSkills = sData?.findAll { !it?.nameByLocale[locale]?.toString() == "EchoSistant5 - ${settings?.defaultInvocation}" || !it?.nameByLocale[locale]?.toString() == "EchoSistant5 - Here" }
        str += customSkills?.size() ? "${str == "" ? "" : "\n"} • Custom Skills: (${customSkills?.size()})" : ""
    }
    return str == "" ? null : str
}

def getAppSettingsDesc() {
	def str = ""
    str += settings?.feedbackType != null && settings?.feedbackType != "default" ? " • Feedback Type: (${strCapitalize(settings?.feedbackType)})" : ""
    str += settings?.quietMode == true ? "${str != "" ? "\n" : ""} • Night Mode: (True)" : ""
    str += settings?.testMode == true ? "${str != "" ? "\n" : ""} • Test Mode: (True)" : ""
    str += settings?.sendDevCmdsAlways == false ? "${str != "" ? "\n" : ""} • Command Opt: (Off)" : ""
	return str != "" ? str : null
}

def getAppNotifDesc() {
	def str = ""
	str += settings?.sendAppUpdateMsg != false ? "• Code Updates: (${strCapitalize(settings?.sendAppUpdateMsg ?: "True")})" : ""
	return str != "" ? str : null
}

def getAppNotifConfDesc() {
	def str = ""
	if(pushStatus()) {
		def ap = getAppNotifDesc()
		def nd = getRestrictSchedDesc("notifQuiet")
        str += (settings?.recipients || settings?.usePush || settings?.phone) ? "Send Using: " : ""
		str += (settings?.recipients) ? "(Contact Book)" : ""
		str += (settings?.usePush) ? "(Push Message)" : ""
		str += (settings?.phone) ? "(SMS Message)" : ""
		str += (ap) ? "\nUpdate Alerts: (Enabled)" : ""
		str += (nd) ? "\nRestrictions: (Enabled)" : ""
	}
	return str != "" ? str : null
}

def getSecSettingsDesc() {
	def str = ""
	str += (settings?.masterSecPIN) ? "Master PIN Set: (True)" : ""
    def expireTime = atomicState?.tempPinSetDt ? secondsTimeDesc(86400 - getPinSetExpireSec(), true) : null
	str += (settings?.tempSecPIN) ? "${str == "" ? "" : "\n"}Guest PIN Expires:\n └ (${expireTime})" : ""
	return str != "" ? str : null
}

def buildNotifPrefMap() {
	def res = [:]
	res["app"] = [:]
	res?.app["updates"] = [
		"updMsg":(settings?.sendAppUpdateMsg == false ? false : true),
		"updMsgWait":(settings?.updNotifyWaitVal == null ? 43200 : settings?.updNotifyWaitVal.toInteger())
	]
	res["msgDefaultWait"] = (settings?.notifyMsgWaitVal == null ? 3600 : settings?.notifyMsgWaitVal.toInteger())
	return res
}

def getRestrictSchedDesc(type) {
	def sun = getSunriseAndSunset()
	//def schedInverted = settings?.DmtInvert
    def typeDesc = type in ["quietMode", "notifQuiet"] ? "Quiet Mode" : "Feedback"
	def startInput = settings?."${type}StartInput"
	def startTime = settings?."${type}StartTime"
	def stopInput = settings?."${type}StopInput"
	def stopTime = settings?."${type}StopTime"
	def dayInput = settings?."${type}Days"
	def modeInput = settings?."${type}Modes"
	def desc = ""
	def timeStartLbl = ( (startInput == "Sunrise" || startInput == "Sunset") ? ( (startInput == "Sunset") ? epochToTime(sun?.sunset.time) : epochToTime(sun?.sunrise.time) ) : (startTime ? time2Str(startTime,true,"h:mm a") : "") )
	def timeStopLbl = ( (stopInput == "Sunrise" || stopInput == "Sunset") ? ( (stopInput == "Sunset") ? epochToTime(sun?.sunset.time) : epochToTime(sun?.sunrise.time) ) : (stopTime ? time2Str(stopTime,true, "h:mm a") : "") )
	desc += (timeStartLbl && timeStopLbl) ? " • ${typeDesc} Time: ${timeStartLbl} - ${timeStopLbl}" : ""
	def days = getInputToStringDesc(dayInput)
	def modes = getInputToStringDesc(modeInput)
	desc += days ? "${(timeStartLbl || timeStopLbl) ? "\n" : ""} • Day${isPluralString(dayInput)}: ${days}" : ""
	desc += modes ? "${(timeStartLbl || timeStopLbl || days) ? "\n" : ""} • Mode${isPluralString(modeInput)}: (${modes})" : ""
	return (desc != "") ? "${desc}" : null
}

def donationPage() {
	return dynamicPage(name: "donationPage", title: "", nextPage: "mainPage", install: false, uninstall: false) {
		section("") {
			def str = ""
			// str += "Hello User, \n\nPlease forgive the interuption but it's been 30 days since you installed/updated this SmartApp and we wanted to present you with this reminder that we do accept donations (We do not require them)."
			// str += "\n\nIf you have been enjoying our software and devices please remember that we have spent thousand's of hours of our spare time working on features and stability for those applications and devices."
			// str += "\n\nIf you have already donated please ignore and thank you very much for your support!"

			// str += "\n\nThanks again for using Echosistant"
			// paragraph str, required: true, state: null
			// href url: textDonateLink(), style:"external", required: false, title:"Donations",
			// 	description:"Tap to open in browser", state: "complete", image: getAppImg("donate.png")
		}
		def iData = atomicState?.installData
		iData["shownDonation"] = true
		atomicState?.installData = iData
	}
}

/*************************************************************************************************************
CREATE INITIAL TOKEN
************************************************************************************************************/
def getAccessToken() {
    try {
        if(!atomicState?.accessToken) {
            LogAction("SmartThings Access Token Not Found... Creating a New One!!!","info", true)
            atomicState?.accessToken = createAccessToken()
        } else { return true }
    }
    catch (ex) {
        log.error "Error: OAuth is not Enabled for ${app?.label}!.  Please click remove and Enable Oauth under the SmartApp App Settings in the IDE"
        return false
    }
}

void resetSTAccessToken() {
    LogAction("Resetting SmartApp Access Token....","warn",true)
    revokeAccessToken()
    atomicState?.accessToken = null
    if(getAccessToken()) {
        LogAction("${app.label} OAuth Access Token Reset was Successful...","info", true)
        //settingUpdate("resetSTAccessToken", "false", "bool")
        atomicState?.tokenResetActive = false
    }
}

/***********************************************************************************************************
        LAMBDA DATA MAPPING
************************************************************************************************************/
def getProfileDevUpdSettings() {
    return [sync:settings?.profileRoomSyncWithST, newOnly:settings?.profileAddNewDevOnly, nameOverride:settings?.profileOvrNameWithST]
}

def getHostForLambda() {return getApiServerUrl().replace("https://","")}

def lambdaSetupRespHandler() {
    def data = request?.JSON
    def returnJson = false
    def firstInstall = false
    log.debug "lambdaSetupResp: $data"
    if(data && data != [:]) {
        if (data['firstInstall'] == true) { 
            sendMsg("EchoSistant Install", "\n\nStack Install (Step 1) has Completed Successfully.  Please return to the SmartApp to move on to the next step.", true, null, null, null, null, true)
            firstInstall = true 
            data['firstInstallDt'] = getDtNow()
        } 
        else { data['firstInstall'] = false }
        data["dt"] = getDtNow()
        data?.each { li->
            updLambdaDataMap(li?.key, li?.value)
        }
        returnJson = true
    } else {
        if(!data || data == [:]) {
        	LogAction("Something went wrong.  We didn't receive the lambda response data.", "warn", true)
        }
    }
    def json = new JsonOutput().toJson([gotData:returnJson])
	def res = new JsonOutput().prettyPrint(json)
    if (!firstInstall){
    	schedLambdaStatusUpd(10, " | (AWS Stack Updated)", true)
    }
    render contentType: "application/text", data: res
}

/*************************************************************************************************************
        ROOM DATA METHODS
************************************************************************************************************/
def roomDataGetRequest() {
    def pId = params?.appId
    log.debug "profile($pId) requesting skill setup instructions"
    def cApp = childApps?.find { it?.getId() == pId }
    if(cApp) { return cApp?.getRoomDataParser() }
}

def processRoomData() {
    def good = true
    def msg = ""
    def data = request?.JSON
    // log.debug "rooms: $data"
    def storApp = getStorageApp()
    if(!storApp) {
        LogAction("Storage Child App Missing.  Did you install the file for this program?", "error", true)
        good = false; msg = "Storage App is Missing";
    }
    if(data == null) {
        LogAction("Something went wrong.  We didn't receive your room data from the web page.", "warn", true)
        good = false; msg = "Invalid Room Data Received";
    }
    if(good) {
        if(data?.rooms?.size()) {
            def rl = []
            data?.rooms?.findAll { it?.locationId == location?.getId() }?.each { rm->
                def tmp = getRoomMap(rm)
                if(tmp) { rl.push(tmp) }
            }
            log.debug "(${rl?.size()}) Rooms Received from SmartThings"
            storApp?.stateUpdate("stRoomMap", rl)
            atomicState?.stRoomDataUpdatedDt = getDtNow()
            atomicState?.roomDevChgsPending = true
        } else {
            LogAction("Oops! It looks like you don't have any rooms configured.", "warn", true)
            msg = "No Rooms Configured for Location"
        }
    }
    def json = new JsonOutput().toJson([gotRooms:good, msg:msg])
	def res = new JsonOutput().prettyPrint(json)
    render contentType: "application/text", data: res
}

def getRoomMap(roomMap) {
    //LogAction("Building Room Map","trace",true)
    if(roomMap) {
        roomMap = roomMap.findAll { !(it?.key in ["backgroundImage", "heroDeviceId", "sortOrder", "dateCreated"]) }
        if(roomMap?.devices) {
            def tmp = []
            roomMap?.devices?.each { dev -> tmp.push(dev?.findAll { it?.key in ["id","name","hubId","locationId","label"] }) }
            if(tmp?.size()) { roomMap?.devices = tmp }
        }
    }
    return roomMap
}

/*************************************************************************************************************
        DEVICE INPUT MANAGEMENT METHODS
************************************************************************************************************/
def masterDeviceList(onlyIds=false) {
	def devs = []
	def devSets = getSettings()?.findAll {it?.key?.startsWith("dev:")}
	devSets?.each { ds->
		def dlst = onlyIds ? ds?.collect {it?.id} : ds
		devs = devs + dlst
	}
    return devs
}

void updateDeviceInputs(data, auto=true) {
    if(auto && !data) { return }
    else {
        def devList = []
        def newList = []
        if(auto) {
            data?.each { rm ->
                devList = devList + rm?.devices?.collect { it?.id }
            }
            devList?.each { dev ->
                if(!newList?.collect { it }?.contains(dev)) { newList << dev }
            }
        } else {
            devList = settings["dev:actuator"] ?: [] + settings["dev:sensor"] ?: []
            devList?.each { dev ->
                if(!newList?.collect { it?.id }?.contains(dev?.id)) { newList << dev?.id }
            }
        }
        settingUpdate("allDevices", newList, "capability.actuator")
        LogAction("updateDeviceInputs(${settings["allDevices"]?.size()})","trace", true)
        atomicState?.roomDevChgsPending = false
    }
}

def getDeviceCapabList(data=null) {
    def lst = []
    def items = data ?: settings["allDevices"]
    items?.each { ad->
		def caps = ad?.capabilities?.collect { it as String }
		lst = lst + caps
    }
    lst = lst?.sort().unique()
	return lst
}

def getStRoomDataById(rmId) {
    def sApp = getStorageApp()
    def rmData = sApp?.getStateVal("stRoomMap") ?: []
	return rmData?.find {it?.id == rmId} ?: null
}

def getStRoomNameById(rmId) {
	def sApp = getStorageApp()
    def rmData = sApp?.getStateVal("stRoomMap") ?: []
	def room = rmData?.find {it?.id == rmId}
	return room?.name ?: null
}

def convCapabNameToInputStr(name) {
    def spl = name?.split(" ")
    def cnt = 1
    name = ""
    spl?.each {
        name += cnt==1 ? it?.toLowerCase() : it
        cnt=cnt+1
    }
    return name
}

/************************************************************************************************************
        LAMBDA DB METHODS
************************************************************************************************************/
def lambdaStateUpdData(chgsOnly=false) {
    def res = [:]
	try {
        // if(!atomicState?.appMaintInProg) {
            def devdata = getDeviceStateMap(chgsOnly)
            def locdata = getLocationMap()
            def setdata = getSetDataMap()
            res = createDevLocDbMap(locdata, devdata, setdata)
        // }
	} catch (ex) {
		//log.error "getDeviceStateMap Exception:", ex
		LogAction("lambdaStateUpdData Exception: ${ex}", "error", true)
	}
    return res
}

def dbDataMap() {
    def res = [:]
	try {
        // if(!atomicState?.appMaintInProg) {
            res["devData"] = getDeviceStateMap(chgsOnly)
            res["locData"] = getLocationMap()
            res["setData"] = getSetDataMap()
        // }
	} catch (ex) {
		//log.error "getDeviceStateMap Exception:", ex
		LogAction("dbDataMap Exception: ${ex}", "error", true)
	}
    return res
}

def createDevLocDbMap(ldata, ddata, sdata) {
    def res = [:]
    def tmp = [:]
    tmp["theId"] = "esData"
    tmp["mapAttr"] = [:]
    tmp?.mapAttr["devData"] = ddata
    tmp?.mapAttr["locData"] = ldata
    tmp?.mapAttr["settings"] = sdata
    res["Item"] = tmp
    res["TableName"] = "EchoSistantV5"
    return res
}

def awsDBType(obj) {
    def val = obj?.value ?: obj
    def rt = [:]
    if(val != null) {
        if(val instanceof String) {obj?.value ? (rt["${obj?.key}"] = ["S":obj?.value]) : (rt["S"] = obj)}
        else if(val instanceof Collection) {obj?.value ? (rt["${obj?.key}"] = ["SS":obj?.value]) : (rt["SS"] = obj)}
        else if(val instanceof Boolean) {obj?.value ? (rt["${obj?.key}"] = ["BOOL":obj?.value]) : (rt["BOOL"] = obj)}
        else if(val instanceof List) {obj?.value ? (rt["${obj?.key}"] = ["L":obj?.value]) : (rt["L"] = obj)}
        else if(val instanceof Integer || val instanceof Double || val instanceof Long || val instanceof BigInteger || val instanceof BigDecimal) {
            obj?.value ? (rt["${obj?.key}"] = ["N":"${obj?.value}"]) : (rt["N"] = "${obj}")}
    	else if (val instanceof Map) {
            def tmp = [:]
            val?.each { c-> tmp << awsDBType(c) }
        	obj?.value ? (rt["${obj.key}"] = ["M":tmp]) : (rt["M"] = tmp)
        }
    }
    else {
    	rt["${obj?.key}"] = ["S": null]
    }
    return rt
}

def sendLambdaStatusUpdate(frc=false) {
	//LogAction("sendLambdaStatusUpdate($frc) | devUpd: (${atomicState?.lambdaDevStateUpdNeeded}) | locUpd: (${atomicState?.lambdaLocStateUpdNeeded})", "trace", true)
    if(frc == true || atomicState?.ok2SendLambdaData || (atomicState?.lambdaDevStateUpdNeeded != false || atomicState?.lambdaLocStateUpdNeeded != false)) {
        if(getAwsAccess() && getAwsAccessSecret()) {
            queueAwsData(lambdaStateUpdData((!frc)), "/ES/esData", "", awsLambdaBaseUrl(), "execute-api", getAwsRegion(), "post", "EsData")
        } else { LogAction("Your AWS ID or Secret is missing.  Please correct this issue.", "error", true) }
    }
}

def awsLambdaBaseUrl() { return atomicState?.lambdaData?.APIURL }

def queueAwsData(data, pathVal, query=[], url, service, region, cmdType=null, dType=null) {
	//LogAction("queueAwsData(${data}, ${pathVal}, $cmdType, $dType", "trace", true)
    def logOut = []
	def result = false
    def json = new JsonOutput().toJson(data)
    def params = [uri: url, path: pathVal, headers: ["Content-Type":"application/json"] + getSig4Auth(url, (data == "" ? data : json.toString()), pathVal, query, cmdType, service, region)]
    if(query?.size()) { params["query"] = query }
    if(data && data != "") { params["body"] = json.toString() }
    // logOut << "params: [uri: $url, path: $pathVal, headers: ${getSig4Auth(url, json.toString(), pathVal, cmdType, service, region)}]"
    def typeDesc = dType ?: "Data"
	try {
		if(!cmdType || cmdType == "put") {
			asynchttp_v1.put(processAwsResponse, params, [ type: "${typeDesc}"])
			result = true
		} else if (cmdType == "post") {
            asynchttp_v1.post(processAwsResponse, params, [ type: "${typeDesc}"])
			result = true
		} else if (cmdType == "get") {
			asynchttp_v1.get(processAwsResponse, params, [ type: "${typeDesc}"])
			result = true
		} else { LogAction("queueAwsData UNKNOWN cmdType: ${cmdType}", warn, true) }
	} catch(ex) {
		log.error "queueAwsData (type: data) Exception:", ex
        // logOut << ex?.message
	}
    // atomicState?.logOut = logOut
	return result
}

def processAwsResponse(response, data) {
	//LogAction("processAwsResponse()", "trace", true)
    def hadIssue = true
	try {
        def type = data?.type
        def rs = response?.status
        // log.debug "resp: ${response.data}"
        def respJson = response?.json
		if(rs == 200) {
            if(type=="EsData") {
                LogAction("processAwsResponse: (${type}) Data Sent SUCCESSFULLY", "info", true)
                atomicState?.lastLambaStateUpdDt = getDtNow()
                respJson?.lambdaInfo?.each { li-> updLambdaDataMap(li?.key, li?.value) }
                // if(atomicState?.uploadAnalyticsNow == true && respJson?.uploadedAnalytics == true) { atomicState?.uploadAnalyticsNow = false }
                atomicState?.lambdaDevStateUpdNeeded = false
                atomicState?.lambdaLocStateUpdNeeded = false
                atomicState?.lambdStatusUpdSchedVal = null
                if(atomicState?.appMaintInProg != false) {
                    atomicState?.appMaintInProg = false
                    log.trace "AppMaintenance is NOW COMPLETE!!!!"
                }
            } else if (type=="awsV5StackDelete") {
                log.debug "processAwsResponse: (${type}) | AWS EchoSistantV5 Stack is being Deleted!"
                //atomicState?.lambdaData = null
            } else if (type=="awsHelperStackDelete") {
                log.debug "processAwsResponse: (${type}) | AWS EchoSistantHelper Stack is being Deleted!"
                atomicState?.lambdaData = null
            } else {
                LogAction("processAwsResponse: (${type}) Request Sent SUCCESSFULLY", "info", true)
            }
            hadIssue=false
		}
		else {
			LogAction("processAwsResponse: 'Unexpected' Response: ${response?.status}", "warn", true)
		}
		if(response?.hasError()) { LogAction("processAwsResponse: errorData: ${response.errorData} | errorMessage: ${response.errorMessage} | warning messages: ${response.warningMessages}", "error", true) }
	} catch(ex) {
        if(response?.hasError()) { LogAction("processAwsResponse: errorData: ${response.errorData} | errorMessage: ${response.errorMessage} | warning messages: ${response.warningMessages}", "error", true) }
	}
    if(hadIssue) { schedLambdaStatusUpd(30, " | (Retry Last Attempt Failed)", true) }
}

def awsStackAction(stackAction, stackName, actType) {
	def url = "https://cloudformation.${getAwsRegion()}.amazonaws.com"
	log.trace "stackAction: ${stackAction} | stackName: ${stackName}"
	if(getAwsAccess() && getAwsAccessSecret()) {
    	queueAwsData("", "/", [Action: stackAction, StackName: stackName, Version: "2010-05-15"], url, "cloudformation", getAwsRegion(), "get", actType)
    } else { LogAction("Your AWS ID or Secret is missing.  Please correct this issue.", "error", true) }
}

void updLambdaDataMap(key, val) {
    def sData = atomicState?.lambdaData ?: [:]
	sData[key?.toString()] = val
	atomicState?.lambdaData = sData
}

def getDeviceStateMap(chgsOnly) {
    def exTime = now()
    // log.trace "Device Map Requested by Lambda..."
	try {
        def devs = []
        def profApps = getProfileApps()
        def devcnt = 0
        def shrtcnt = 0
        profApps?.each { pa->
            def dMap = pa?.getDeviceMap(chgsnly)
            def dSize = dMap?.size()
            if(dSize > 0) {
                dMap?.each { dv->
                    def exist = devs?.find { it?.deviceId == dv?.deviceId }
                    if(exist) {
                        def rooms = exist["rooms"]
                        dv?.rooms?.each { rm-> rooms << rm }
                        exist["rooms"] = rooms?.sort()?.unique()
                    } else {
                        devs << dv
                        if(dv?.capabilities?.find {it == "Shortcut"}) {shrtcnt=shrtcnt+1}
                        else {devcnt = devcnt+1}
                    }
                }
            }
        }
        // log.info "Profile DeviceMap Returned: (${cnt}) Devices in (${((now()-exTime)/1000).toDouble().round(2)}sec)"
        atomicState?.profDevCnt = devcnt
        atomicState?.profShortcutCnt = shrtcnt
        return devs
	} catch (ex) {
		//log.error "getDeviceStateMap Exception:", ex
		LogAction("getDeviceStateMap Exception: ${ex}", "error", true)
		return null
	}
}

void logTest() {
    def list = atomicState?.logTest ?: []
    list?.each {
        log.debug "$it"
    }
    atomicState?.logTest = null
}

def getAwsAccess() {
    return atomicState?.lambdaData?.awsAccessKey
}

def getAwsAccessSecret() {
    return atomicState?.lambdaData?.awsAccessKeySecret
}

def getAwsRegion() {
    return settings?.awsLocale == "UK" ? "eu-west-1" : "us-east-1" //atomicState?.lambdaData?.awsRegion
}

def getSkillLocale() {
    return settings?.awsLocale == "UK" ? "en-GB" : "en-US"
}

def getFilteredModes() {
    return location?.modes?.collect { ["id":it?.id, "name":it?.name, "type":"Mode"] }?.findAll {!((it?.id as String) in settings?.excludedModes)}?.sort {it?.name}
}

def getFilteredRoutines() {
    return location.helloHome?.getPhrases()?.collect { ["id":it?.id, "name":it?.label, "type":"Routine"] }?.findAll {!((it?.id as String) in settings?.excludedRoutines)}?.sort {it?.name}
}

def getShmIncidents() {
    //Thanks Adrian
    def incidentThreshold = now() - 604800000
    return location.activeIncidents.collect{[date: it?.date?.time, title: it?.getTitle(), message: it?.getMessage(), args: it?.getMessageArgs(), sourceType: it?.getSourceType()]}.findAll{ it?.date >= incidentThreshold } ?: null
}

def getShmStatus() {
    switch (location.currentState("alarmSystemStatus")?.value) { case 'off': return 'Disarmed' case 'stay': return 'Armed/Stay' case 'away': return 'Armed/Away' }
}

def getSecurityPinMap() {
    def pin = [:]
    def mPins = []
    if(settings?.masterSecPIN) { mPins?.push(settings?.masterSecPIN)}
    if(settings?.tempSecPIN) { mPins?.push(settings?.tempSecPIN)}
    pin["master"] = mPins
    return pin
}

def getLocationMap() {
    def exTime = now()
    // log.trace "Location Map Requested by Lambda..."
	try {
        def l = [:]
        def swVer = atomicState?.swVer
        def tz = TimeZone.getTimeZone(location.timeZone.ID)
        checkTempPinExpire()
        l["verInfo"] = [app:releaseVer(), profile:swVer?.profVer, storage:swVer?.storVer, shortcuts:swVer?.shrtCutVer, appVerDt:swVer?.appVerDt]
        l["curStMode"] = location?.mode
        l["availStModes"] = getFilteredModes()
        l["availStRoutines"] = getFilteredRoutines()
        l["availableRooms"] = getRoomList()
        l["stToken"] = atomicState?.accessToken
        l["latitude"] = location?.latitude
        l["longitude"] = location?.longitude
        l["name"] = location?.name
        l["location_id"] = location?.id
        l["temp_scale"] = location?.temperatureScale
        l["timezone"] = location?.timeZone?.ID as String
        l["todDesc"] = getTimeOfDayDesc() as String
        l["zip_code"] = location?.zipCode
        l["sunrise"] = Date.parse("yyyy-MM-dd'T'HH:mm:ss.SSSX", location.currentValue('sunriseTime')).format('h:mm a', tz)
        l["sunset"] = Date.parse("yyyy-MM-dd'T'HH:mm:ss.SSSX", location.currentValue('sunsetTime')).format('h:mm a', tz)
        l["shm_alerts"] = getShmIncidents()
        l["shm_state"] = getShmStatus()
        l["usersAvailable"] = settings?.usersAvailable ? settings.usersAvailable?.toString().split(",").collect { it?.toString().trim() } : []
        l["optInUseAnalytics"] = (atomicState?.appData?.analytics?.allowCmdCollect != false && settings?.optInUseAnalytics ?: false)
        l["sendAnalyticsNow"] = false //(atomicState?.uploadAnalyticsNow == true)
        l["securityPINs"] = getSecurityPinMap()
        l["showBgWallpaper"] = settings?.showBgWallpaper ?: "carbon_fiber"
        //LogAction("LocationMap Data Created in (${((now()-exTime)/1000).toDouble().round(2)}sec)", "info", true)
        return l
	} catch (ex) {
		//log.error "getLocationMap Exception:", ex
		LogAction("getLocationMap Exception: ${ex}", "error", true)
		return null
	}
}

def getSetDataMap() {
    // log.trace "Settings Data Map Requested by Lambda..."
	try {
        def l = [:]
        l["allowPersonality"] = (settings?.allowPersonality == false ? false : true)
        l["followupMode"] = allowFollowupMode()
        l["sendDebugData"] = (settings?.sendDebugData == true ? true : false)
        l["feedbackType"] = getFeedbackType()
        l["sendDevCmdsAlways"] = (settings?.sendDevCmdsAlways == true ? true : false)
        l["quietMode"] = (settings?.quietMode == true ? true : false)
        l["testMode"] = (settings?.testMode == true ? true : false)
        l["adjSetLevel"] = (settings?.adjSetLevel ?: 3)
        l["adjVolLevel"] = (settings?.adjVolLevel ?: 2)
        l["adjTempVal"] = (settings?.adjTempVal ?: 1)
        l["adjFanHigh"] = (settings?.adjFanHigh ?: 99)
        l["adjFanMed"] = (settings?.adjFanMed ?: 66)
        l["adjFanLow"] = (settings?.adjFanLow ?: 33)
        l["adjFanLevel"] = (settings?.adjFanLevel ?: 33)
        return l
	} catch (ex) {
		//log.error "getLocationMap Exception:", ex
		LogAction("getSetDataMap Exception: ${ex}", "error", true)
		return null
	}
}

def getRoomList() {
    def items = []
    def rooms = getProfileApps()
    rooms?.each { rm->
        def t = [:]
        t["name"] = rm?.getRoomName() as String
        t["id"] = rm?.id as String
        items.push(t)
    }
    return items
}

void schedLambdaStatusUpd(wait, evtName=null, frc=false) {
    def curWait = atomicState?.lambdStatusUpdSchedVal ?: null
    def appMaint = (atomicState?.appMaintInProg == true)
    // if(settings["optInUseAnalytics"] && isNewDay()) { atomicState?.uploadAnalyticsNow = true }
    if(frc || curWait == null || ((wait < curWait) && !appMaint)) {
        LogAction("Scheduling Lambda Status Update for (${wait}sec)${evtName ?: ""}", "trace", true)
        runIn(wait, "sendLambdaStatusUpdate", [overwrite: true])
        atomicState?.lambdStatusUpdSchedVal = wait
    }
}

def lambaLocStateUpdReq(frc=false, wait=null, evtName=null) {
    //LogAction("lambaLocStateUpdReq($frc, $wait)", "trace", true)
    if(frc) { sendLambdaStatusUpdate(true) }
    else { schedLambdaStatusUpd((wait ?: 30), evtName) }
    atomicState?.lambdaLocStateUpdNeeded = true
}

def lambaDevStateUpdReq(frc=false, wait=null, evtName=null) {
    // LogAction("lambaDevStateUpdReq($frc, $wait)", "trace", true)
    if(frc) { sendLambdaStatusUpdate(true) }
    else { schedLambdaStatusUpd((wait ?: 30), evtName) }
    atomicState?.lambdaDevStateUpdNeeded = true
}

def getLastLambdaUpdDtSec() { return !atomicState?.lastLambaStateUpdDt ? 7200 : GetTimeDiffSeconds(atomicState?.lastLambaStateUpdDt, null, "getLastLambaStateUpdDtSec").toInteger() }

def getStateSize() { return state?.toString().length() }

def getStateSizePerc() { return (int) ((state?.toString().length() / 100000)*100).toDouble().round(0) }

def getRandomString(length=10, alphaNum=true) {
    def allowed = (['a'..'z','A'..'Z',0..9] + (alphaNum ? [0..9] : [])).flatten()
    def time = new Date()
    Random rand = new Random(time.getTime())
    def strChars = (0..length).collect { allowed[rand.nextInt(allowed.size())] }
    return strChars.join()
}

def preReqCheck() {
	//LogAction("preReqCheckTest()", "trace", true)
	if(!atomicState?.installData) { atomicState?.installData = ["initVer":releaseVer(), "dt":getDtNow().toString(), "updatedDt":"Not Set", "freshInstall":true, "shownDonation":false, "shownFeedback":false, "shownChgLog":true] }
	if(!location?.timeZone || !location?.zipCode) {
		atomicState.preReqTested = false
		LogAction("SmartThings Location not returning (TimeZone: ${location?.timeZone}) or (ZipCode: ${location?.zipCode}) Please edit these settings under the IDE", "warn", true)
		return false
	} else {
		atomicState.preReqTested = true
		return true
	}
}

def handleDevEvt(evt, chldLbl) {
    checkQuietMode()
    def evtStr = " (${evt?.name.toUpperCase()} Event | ${evt?.displayName})"
    if(atomicState?.ok2SendLambdaData == true) {
        lambaDevStateUpdReq(false, getEvtWait(evt?.name), evtStr)
        //LogAction("${evt?.name.toUpperCase()} Event | Device: ${evt?.displayName} | Value: (${strCapitalize(evt?.value)}${evt.unit ? "${evt.unit}" : ""}) with a delay of (${((now()-evt.date.getTime())/1000).toDouble().round(2)}sec) | Profile: (${chldLbl})", "trace", true)
    }
}

def handleLocEvt(evt) {
    checkQuietMode()
    if(atomicState?.ok2SendLambdaData == true) {
        lambaLocStateUpdReq(false, 300, " (${evt?.name} Event | ${strCapitalize(evt?.value)})")
    	//LogAction("Location Event | (${strCapitalize(evt?.value)}) | delay of (${((now()-evt.date.getTime())/1000).toDouble().round(2)}sec)", "trace", true)
    }
}

def handleShmEvt(evt) {
    checkQuietMode()
    if(atomicState?.ok2SendLambdaData == true) {
        lambaLocStateUpdReq(false, 5, " (${evt?.name.toUpperCase()} Event | ${strCapitalize(evt?.value)})")
	    //LogAction("Alarm Status Event | Current Mode: (${strCapitalize(evt?.value)}) | delay of (${((now()-evt.date.getTime())/1000).toDouble().round(2)}sec)", "trace", true)
    }
}

def handleModeEvt(evt) {
    checkQuietMode()
    if(atomicState?.ok2SendLambdaData == true) {
        lambaLocStateUpdReq(false, 5, " (${evt?.name.toUpperCase()} Event | ${strCapitalize(evt?.value)})")
	    //LogAction("Location Mode Event | Current Mode: (${strCapitalize(evt?.value)}) | delay of (${((now()-evt.date.getTime())/1000).toDouble().round(2)}sec)", "trace", true)
    }
}

def getEvtWait(attr) {
    switch(attr) {
        case ["level", "color", "colorTemperature", "hue", "saturation", "activities", "currentActivity", "mute", "status", "trackData", "trackDescription"]:
            return 300
        break
        case ["door", "switch", "power", "energy", "illuminance", "humidity", "temperature", "sleeping", "voltage", "phraseSpoken", "battery"]:
            return 60
        break
        case ["contact", "motion", "powerSource", "thermostatFanMode", "thermostatMode", "thermostatOperatingState", "coolingSetpoint", "heatingSetpoint"]:
            return 15
        break
        case ["lock", "presence", "shock", "sleeping", "alarm", "carbonDioxide", "carbonMonoxide", "smoke", "sound",  "tamper", "water"]:
            return 7
        break
        default:
            return 30
        break
    }
}

def getPrettyDevMap() {
	try {
		def json  = new JsonOutput().toJson(getDeviceStateMap(false))
		def res = new JsonOutput().prettyPrint(json)
		render contentType: "application/json", data: res
	} catch (ex) { log.error "getPrettyDevMap Exception:", ex }
}

def getPrettyLocMap() {
	try {
		def json = new JsonOutput().toJson(getLocationMap())
		def res = new JsonOutput().prettyPrint(json)
		render contentType: "application/json", data: res
	} catch (ex) { log.error "getPrettyLocMap Exception:", ex }
}

def getColorNameMap() {
	try {
		def json = new JsonOutput().toJson(colorUtil.ALL.collect { it?.name?.toLowerCase()})
		def res = new JsonOutput().prettyPrint(json)
		render contentType: "application/json", data: res
	} catch (ex) { log.error "getColorNameMap Exception:", ex }
}

def getColorMap() {
	try {
		def json = new JsonOutput().toJson(colorUtil.ALL)
		def res = new JsonOutput().prettyPrint(json)
		render contentType: "application/json", data: res
	} catch (ex) { log.error "getColorMap Exception:", ex }
}

/************************************************************************************************************
        Base Process
************************************************************************************************************/
def installed() {
    LogAction("Installed with settings: ${settings}", "debug", false)
    atomicState?.isInstalled = true
    atomicState?.installData = ["initVer":releaseVer(), "dt":getDtNow().toString(), "updatedDt":"Not Set", "freshInstall":true, "shownDonation":false, "shownFeedback":false, "shownChgLog":true]
    sendSlackNotif(true)
    initialize()
}

def updated() {
    LogAction("${app?.getLabel()} | Now Running Updated() Method", "trace", true)
    if(!atomicState?.isInstalled) { atomicState?.isInstalled = true }
    //LogAction("Updated with settings: ${settings}", "debug", false)
    unsubscribe()
    initialize()
}

def initialize() {
    if(atomicState?.ok2RunInitialize != true) { return }
    updVersionData("appVer", releaseVer())
    subscriptions()
    if (!atomicState?.accessToken) {
        LogAction("Access token not defined. Attempting to refresh. Ensure OAuth is enabled in the SmartThings IDE.", "error", false)
        getAccessToken()
    }
    app.updateLabel(appName())
    scheduler()
    atomicState?.ok2SendLambdaData = (atomicState?.isInstalled && atomicState?.ok2RunInitialize && atomicState?.lambdaData?.APIURL && atomicState?.lambdaData?.dt)
}

def uninstalled() {
	revokeAccessToken()
    LogAction("${app?.getLabel()} has been Uninstalled...", "warn", true)
}

void scheduler() {
    runIn(4, appMaintTasks, [overwrite: true])
    runIn(180, "updateFollowup", [overwrite: true])
    runEvery3Hours(appCheck)
}

void appMaintTasks() {
    atomicState?.appMaintInProg = true
    unschedule(sendLambdaStatusUpdate)
    stateCleanup()
    settingCleanup()
    checkQuietMode()
    if(settings?.allowTempPIN && settings?.tempSecPIN && atomicState?.tempPinSetDt == null) { atomicState?.tempPinSetDt = getDtNow() }
    runIn(5, "updChildren", [overwrite: true])
    schedLambdaStatusUpd(30, " | (SmartApp Updated)", true)
}

void checkTempPinExpire() {
    if(settings?.allowTempPIN && settings?.tempSecPIN) {
        if(getPinSetExpireSec() >= 86400) {
            settingRemove("allowTempPIN")
            settingRemove("tempSecPIN")
            atomicState?.tempPinSetDt = null
        }
    }
}

def getPinSetExpireSec() { return !atomicState?.tempPinSetDt ? 100000 : GetTimeDiffSeconds(atomicState?.tempPinSetDt, null, "getPinSetExpireSec").toInteger() }

void appCheck() {
	if(getLastWebUpdSec() > (3600*4)) { updateWebStuff() }
    checkIfSwupdated()
	notificationCheck()
    checkQuietMode()
}

void updateFollowup() {
    def profs = getProfileApps()
    atomicState?.profClnRoomNames = profs?.collect { it?.getRoomName(true) }
    atomicState?.profRoomNames = profs?.collect { it?.getRoomName() }
}

void updChildren() {
    def profId = null
    def profVer = null
    def storVer = null
    def storId = null
    def remVer = null
    def remId = null
    def rooms = []
    def roomsCln = []
    def shrtcuts = []
    getChildApps()?.each {
        switch(it?.moduleType()?.toString()) {
            case "profile":
                if(!profVer) { profVer = it?.releaseVer() }
                if(!profId) { profId = it?.smartAppId }
                rooms?.push(it?.getRoomName())
                roomsCln?.push(it?.getRoomName(true))
                // shrtcuts = shrtcuts + it?.getShortcutNames()
                break
            case "storage":
                if(!storVer) { storVer = it?.releaseVer() }
                if(!storId) { storId = it?.smartAppId }
                break
        }
        it?.update()
    }
    // atomicState?.shortcutNames = shrtcuts
    atomicState?.profileAppId = profId
    atomicState?.storageAppId = storId
    if(profVer) { updVersionData("profVer", profVer) }
    if(storVer) { updVersionData("storVer", storVer) }
    runIn(20, "updWebCoREProfs", [overwrite: true])
    //log.debug "profileAppId: ${atomicState?.profileAppId} | profVer: ${atomicState?.swVer?.profVer} | storageAppId: ${atomicState?.storageAppId} | storVer: ${atomicState?.swVer?.storVer}"
}

void updWebCoREProfs() {
    def profiles = [] 
    getProfileApps()?.each { profiles = profiles + it?.getShortcutNames() }
    atomicState?.profTest = profiles
    sendLocationEvent(name: "echoSistant", value: "refresh", data: [profiles: profiles] , isStateChange: true, descriptionText: "EchoSistant Profile Shortcuts List Refresh")
}

void updProfileAppId(id) { atomicState?.profileAppId = id }

void updShortcutAppId(id) { atomicState?.shortcutAppId = id }

void updStorageAppId(id) { atomicState?.storageAppId = id }

def subscriptions() {
    subscribe(app, appTouchHandler)
    //subscribe(location, locationHandler)
    subscribe(location, "mode", handleModeEvt)
    subscribe(location, "sunset", handleLocEvt)
    subscribe(location, "sunrise", handleLocEvt)
    subscribe(location, "alarmSystemStatus", handleShmEvt)
}

def getSettingsData() {return settings?.sort().collect { it }}

def getSettingVal(var) {return settings[var] ?: null}

def getStateVal(var) {return state[var] ?: null}

void appTouchHandler(evt) {
    //app.update()
    updWebCoREProfs()

}

void settingUpdate(name, value, type=null) {
    //log.trace("settingUpdate($name, $value, $type)...")
    if(name && type) { app?.updateSetting("$name", [type: "$type", value: value]) }
    else if (name && type == null) { app?.updateSetting(name.toString(), value) }
}

void settingRemove(name) {
	// LogAction("settingRemove($name)...", "trace", false)
	if(name) { app?.deleteSetting("$name") }
}

def stateCleanup() {
    LogAction("stateCleanup","trace", true)
    def data = [
        "lambdaSettingsData", "tmpRestrictPageData", "curNotifConfigPageData", "lambdaDataUpdDt", "skillDataMap", "logOut", 
        "actionProcDone", "actionMaintPageParams", "actionMaintPassCnt", "esProfiles", "maintResults", "profMaintInProg",
        "profMaintPassCnt", "profMaintStartDt", "roomCrtProcDone", "skillCrtProcDone", "skillMaintPageParams", "skillMaint", 
        "skillMaintStartDt", "skillMaintPassCnt", "skillMaintInProg", "profileMaint", "skillRemovalInProg", "awsLocale"
    ]
    data?.each { item -> if(state?.containsKey(item)) { state.remove(item?.toString()) } }
}

def settingCleanup() {
    LogAction("settingCleanup","trace", true)
    def remove = [
        "cFanLevel", "cHigh", "cInactiveDev", "cLevel", "cLow", "cLowBattery", "cMedium", "cTemperature", "cVolLevel",
        "sFeedback", "sConversation", "conversationMode", "followUpMode", "contCmds", "securityPIN", "tempSecurityPIN", 
        "removeAllProfilesSkills", "clearProfileMaint", "clearActionMaint", "clearLambdaData", "clearSkillAuth",
        "clearSkillMaint", "deleteAwsStacks", "dev:actuator", "dev:sensor", "profileSkillsSelected", 
    ]
    def migItems = [
        "bool":["addOnlyNewDevsToExistingProfiles":"profileAddNewDevOnly", "ovrideProfNameStRoom":"profileOvrNameWithST", "keepStRoomsProfilesInSync":"profileRoomSyncWithST", "disFollowupOnQuietMode":"disableFollowupOnQuiet"],
        "enum":["exclRoutines":"excludedRoutines", "exclModes":"excludedModes", "exclRooms":"excludedRooms"]
    ]
    
    migItems?.each { mk->
        mk?.value?.each { mi->
            if(settings?.containsKey(mi?.key)) {
                settingUpdate(mi?.value, settings[mi?.key], mk?.key)
                remove?.push(mi?.key)
            }
        }
    }
    remove?.each { item -> app.deleteSetting(item?.toString()) }
}

// def childUninstalled() {
// 	log.debug "Profile has been deleted, refreshing Profiles for webCoRE, ${getProfileApps()*.label}""
//     sendLocationEvent(name: "echoSistant", value: "refresh", data: [profiles: getProfileList()] , isStateChange: true, descriptionText: "echoSistant Profile list refresh")
// } 

def getStorStateVal(val) {
    def storApp = getStorageApp()
    if(val && storApp) {
        return storApp?.getStateVal(val as String) ?: null
    }
}

def updStorStateVal(sKey, sValue) {
    def storApp = getStorageApp()
    if(sKey && storApp) {
        return storApp?.stateUpdate(sKey as String, sValue)
    }
}

def preSymObj() { [1:"•", 2:"│", 3:"├", 4:"└", 5:"    ", 6:"┌", 7:"├──", 8:"└── "] }

def lambdaZip(verStr="") { return "https://echosistant.com/super/secret/folder/nothing/here/2484yddjdy4/EchoSistantV5.zip${verStr}"}

def awsSdkJs(verStr="") { return "https://echosistant.com/es5_content/js/aws-sdk.min.js${verStr}"}

def esWebHeadHtml(title, verStr="") {
    return """
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <meta name="description" content="${title}">
        <meta name="author" content="Anthony S.">
        <meta http-equiv="cleartype" content="on">
        <meta name="MobileOptimized" content="320">
        <meta name="HandheldFriendly" content="True">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <title>${title}</title>
        <link href="https://fonts.googleapis.com/css?family=Roboto" rel="stylesheet">
        <script src="https://use.fontawesome.com/a81eef09c0.js" defer></script>
        <script src="https://code.jquery.com/jquery-3.2.1.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4=" crossorigin="anonymous"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/wow/1.1.2/wow.min.js" defer></script>
        <link href="https://echosistant.com/es5_content/css/es5_master.min.css" rel="stylesheet">
        <link href="https://echosistant.com/es5_content/css/es5_web.min.css" rel="stylesheet">

    """
}

def esWebFooterHtml(verStr="") {
    return """
        <footer class="page-footer center-on-small-only fixed-bottom">
            <div class="footer-copyright">
                <div class="containter-fluid">
                    © 2018 Copyright<a href="https://www.EchoSistant.com"> EchoSistant.com</a>
                </div>
            </div>
        </footer>
        <script type="text/javascript" src="https://echosistant.com/es5_content/js/popper.min.js" defer></script>
        <script type="text/javascript" src="https://echosistant.com/es5_content/js/bootstrap.min.js" defer></script>
        <script type="text/javascript" src="https://echosistant.com/es5_content/js/mdb.min.js" defer></script>
    """
}

def getLoaderAnimation() {
    return """
        <svg id="loader" height="100%" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid" class="lds-double-ring">
            <circle cx="50" cy="50" ng-attr-r="{{config.radius}}" ng-attr-stroke-width="{{config.width}}" ng-attr-stroke="{{config.c1}}" ng-attr-stroke-dasharray="{{config.dasharray}}" fill="none" stroke-linecap="round" r="40" stroke-width="7" stroke="#18B9FF" stroke-dasharray="62.83185307179586 62.83185307179586" transform="rotate(139.357 50 50)">
            <animateTransform attributeName="transform" type="rotate" calcMode="linear" values="0 50 50;360 50 50" keyTimes="0;1" dur="1.8s" begin="0s" repeatCount="indefinite"></animateTransform>
            </circle>
            <circle cx="50" cy="50" ng-attr-r="{{config.radius2}}" ng-attr-stroke-width="{{config.width}}" ng-attr-stroke="{{config.c2}}" ng-attr-stroke-dasharray="{{config.dasharray2}}" ng-attr-stroke-dashoffset="{{config.dashoffset2}}" fill="none" stroke-linecap="round" r="32" stroke-width="7" stroke="#FF7F27" stroke-dasharray="50.26548245743669 50.26548245743669" stroke-dashoffset="50.26548245743669" transform="rotate(-139.357 50 50)">
            <animateTransform attributeName="transform" type="rotate" calcMode="linear" values="0 50 50;-360 50 50" keyTimes="0;1" dur="1.8s" begin="0s" repeatCount="indefinite"></animateTransform>
            </circle>
            <text id="loaderText1" fill="gray" stroke-width="0" x="50%" y="50%" text-anchor="middle" class="loaderText">Please</text>
            <text id="loaderText2" fill="gray" stroke-width="0" x="50%" y="60%" text-anchor="middle" class="loaderText">Wait</text>
        </svg>
    """
}

//TODO: Add location data (Current Mode / Sunrise / Sunset)
//TODO: Split the devices up and group by capabilities
//TODO: Add cap icons to the groups
//TODO: Add the current states to the device info (On/Off / Battery / Temp)

def getRefPage() {
    def randVerStr = "?=${now()}"
	def html = ""
    try {
        html = """
            <html lang="en">
                <head>
                    ${esWebHeadHtml("EchoSistant Reference", randVerStr)}
                    <style>
                    </style>
                    <script>
                        var stData = '${getAppEndpointUrl("getDbData")}';
                    </script>
                </head>
                <body>
                    <header>
                        <!--Navbar-->
                        <nav class="navbar navbar-dark sticky-top navbar-expand-lg">
                            <a class="navbar-brand" href="#"><img src="https://echosistant.com/es5_content/images/es5_logo.png" height="30" class="d-inline-block align-top" alt=""> EchoSistant Reference</a>

                            <!-- Collapse button -->
                            <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent"
                                aria-expanded="false" aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>

                            <!-- Collapsible content -->
                            <div class="collapse navbar-collapse" id="navbarSupportedContent">

                                <!-- Links -->
                                <ul class="navbar-nav mr-auto">
                                    <li class="nav-item active">
                                        <a class="nav-link" href="#">Home <span class="sr-only">(current)</span></a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href="#profile_list">Profiles</a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href="#routine_list">Routines</a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href="#mode_list">Modes</a>
                                    </li>
                                </ul>
                                <!-- Links -->

                                <!-- Search form -->
                                <!-- <form class="form-inline">
                                    <input class="form-control mr-sm-2" type="text" placeholder="Search" aria-label="Search">
                                </form> -->
                            </div>
                            <!-- Collapsible content -->

                        </nav>
                        <!--/.Navbar-->
                    </header>

                    <main>
                        <!--Main layout-->
                        <div class="container">
                            <section id="stContent">
                                <div id="loaderDiv" style="width: 100%; height: 200px; text-align: center;">
                                    <h2 class="h2-responsive mb-2" style="font-weight: 400;">Content Loading</h2>
                                    <div class="row fadeIn fadeOut">
                                        <div class="col-lg-12 mb-r">
                                            ${getLoaderAnimation()}
                                        </div>
                                    </div>
                                </div>
                            </section>
                        </div>
                        <!--/.Main layout-->
                    </main>

                    <!--Footer-->
                    ${esWebFooterHtml(randVerStr)}
                    <script type="text/javascript" src="https://echosistant.com/es5_content/js/es5_ref.js${randVerStr}"></script>
                    <script>
                        \$(this).scrollTop(0);
                        getStContentSect();
                    </script>
                </body>
            </html>
		"""
	} catch (ex) {
        log.error "getRefPage Exception:", ex
        html = """'<p>There was an Error trying to generate the ST Content</p><br/><p>${ex?.message}</p>'"""
    }
    render contentType: "text/html", data: html, status: 200
}

def stUpdateHtml() {
    def randVerStr = "?=${now()}"
    def html = ""
    if(lambdaIsConfigured()) {
    	html = """
        <html lang="en">
        <head>
            ${esWebHeadHtml("EchoSistant Updater", randVerStr)}
            <script src="${awsSdkJs()}"></script>
            <script type="text/javascript">
                var functionType = "updates";
                var userRegion = '${getAwsRegion()}';
                var accessKeyId = '${getAwsAccess()}';
                var secretAccessKey = '${getAwsAccessSecret()}';
                var appIds = ${new JsonOutput().toJson(getIdeAppIds())};
                // console.log( "appIds", appIds);
                var zipUrl = '${lambdaZip(randVerStr)}';
                var authUrl = '${apiServerUrl("/hub")}';
                var upd1Url = '${apiServerUrl("/github/appRepoStatus?appId=")}';
                var upd2Url = '${apiServerUrl("/ide/app/updateOneFromRepo/")}';
                var upd3Url = '${apiServerUrl("/ide/app/publishAjax/")}';
            </script>
            <script src="https://echosistant.com/es5_content/js/es5_web.js${randVerStr}" async></script>
        </head>
        <body>
            <header>
                <nav class="navbar navbar-dark sticky-top navbar-expand-lg">
                    <a class="navbar-brand" href="#"><img src="https://echosistant.com/es5_content/images/es5_logo.png" height="30" class="d-inline-block align-top" alt=""> EchoSistant</a>
                </nav>
            </header>
            <main>
                <div class="container">
                    <section id="stContent">
                        <div style="width: 100%; height: 200px; text-align: center;">
                            <h2 class="h2-responsive mb-2" style="font-weight: 400;">Software Updater</h2>
                            <hr class="white">
                            <div id="loaderDiv" class="row fadeIn fadeOut">
                                <div class="col-lg-12 mb-r">
                                    ${getLoaderAnimation()}
                                </div>
                            </div>
                            <div class="row fadeIn fadeOut">
                                <div class="col-lg-12 mb-r">
                                    <div class="listDiv">
                                        <div id="resultList">
                                            <h3 id="resultsTitle" style="display: none;">Update Results</h3>
                                            <ul id="resultUl"></ul>
                                        </div>
                                    </div>
                                    <i id="finishedImg" class='fa fa-check' style="display: none;"></i>
                                    <div id="results"></div>
                                </div>
                            </div>
                        </div>
                    </section>
                </div>
            </main>
            ${esWebFooterHtml(randVerStr)}
        </body>
        </html>"""
        // runIn(5, "updChildren", [overwrite: true])
    } else { html = "Unable to perform updates because you are missing the required AWS ID and/or Secret" }
    render contentType: "text/html", data: html
}

def stRoomsHtml() {
    def randVerStr = "?=${now()}"
	def html = """
        <html lang="en">
            <head>
                ${esWebHeadHtml("EchoSistant Rooms", randVerStr)}
                <style>
                </style>
                <script>
                    var functionType = "rooms";
                    var authUrl = '${apiServerUrl("/hub")}';
                    var roomsUrl = '${apiServerUrl("/api/rooms")}';
                    var stLocId = '${location?.id}';
                    var sendRoomUrl = '${getAppEndpointUrl("rDataCol")}';
                </script>
                <script src="https://echosistant.com/es5_content/js/es5_web.js${randVerStr}" async></script>
            </head>
            <body>
                <header>
                    <nav class="navbar navbar-dark sticky-top navbar-expand-lg">
                        <a class="navbar-brand center" href="#"><img src="https://echosistant.com/es5_content/images/es5_logo.png" height="30" class="d-inline-block align-top" alt=""> EchoSistant</a>
                    </nav>
                </header>
                <main>
                    <div class="container">
                        <section id="stContent">
                            <div style="width: 100%; height: 200px; text-align: center;">
                                <h2 class="h2-responsive mb-2" style="font-weight: 400;">SmartThings Rooms</h2>
                                <hr class="white">
                                <div id="loaderDiv" class="row fadeIn fadeOut">
                                    <div class="col-lg-12 mb-r">
                                        ${getLoaderAnimation()}
                                    </div>
                                </div>
                                <div class="row fadeIn fadeOut">
                                    <div class="col-lg-12 mb-r">
                                        <div class="listDiv">
                                            <div id="resultList">
                                                <h3 id="resultsTitle" style="display: none;">Room Results</h3>
                                                <ul id="resultUl"></ul>
                                            </div>
                                        </div>
                                        <i id="finishedImg" class='fa fa-check' style="display: none;"></i>
                                        <div id="results"></div>
                                        <div id="errResults"></div>
                                    </div>
                                </div>
                            </div>
                        </section>
                    </div>
                </main>
                ${esWebFooterHtml(randVerStr)}
            </body>
        </html>
    """
    render contentType: "text/html", data: html
}

def awsUtilHtml() {
    def randVerStr = "?=${now()}"
    def html = ""
    if(getAwsAccess() && getAwsAccessSecret()) {
        html = """
        <html lang="en">
        <head>
            ${esWebHeadHtml("EchoSistant Stack Utility")}
            <script src="${awsSdkJs()}"></script>
            <script>
                var functionType = "stackUtil";
                var userRegion = '${getAwsRegion()}';
                var accessKeyId = '${getAwsAccess()}';
                var secretAccessKey = '${getAwsAccessSecret()}';
                var zipUrl = '${lambdaZip()}';
                var stAwsResp = '${getAppEndpointUrl("stackResp")}';
                var stPath = '/api/smartapps/installations/${app?.id}/process?access_token=${atomicState?.accessToken}';
                var stHost = '${getHostForLambda()}';
                var stackTemplate = '{"Resources":{"EchoSistantDB":{"Type":"AWS::DynamoDB::Table","Properties":{"ProvisionedThroughput":{"ReadCapacityUnits":"5","WriteCapacityUnits":"5"},"AttributeDefinitions":[{"AttributeName":"theId","AttributeType":"S"}],"TableName":"EchoSistantV5","KeySchema":[{"AttributeName":"theId","KeyType":"HASH"}]}},"EchoSistantV5AlexaPermissions":{"Type":"AWS::Lambda::Permission","Properties":{"Principal":"alexa-appkit.amazon.com","FunctionName":{"Ref":"EchoSistantV5"},"Action":"lambda:InvokeFunction"}},"EchoSistantV5ApiPermissions":{"Type":"AWS::Lambda::Permission","Properties":{"FunctionName":{"Fn::GetAtt":["EchoSistantV5","Arn"]},"Action":"lambda:InvokeFunction","Principal":"apigateway.amazonaws.com","SourceArn":{"Fn::Join":["",["arn:aws:execute-api:",{"Ref":"AWS::Region"},":",{"Ref":"AWS::AccountId"},":",{"Ref":"ESRestApi"},"/ES/ANY/{proxy+}"]]}}},"EchoSistantV5ApiPermissionsES":{"Type":"AWS::Lambda::Permission","Properties":{"FunctionName":{"Fn::GetAtt":["EchoSistantV5","Arn"]},"Action":"lambda:InvokeFunction","Principal":"apigateway.amazonaws.com","SourceArn":{"Fn::Join":["",["arn:aws:execute-api:",{"Ref":"AWS::Region"},":",{"Ref":"AWS::AccountId"},":",{"Ref":"ESRestApi"},"/*/*/{proxy+}"]]}}},"ESRestApi":{"Type":"AWS::ApiGateway::RestApi","Properties":{"Name":"ES"},"DependsOn":["EchoSistantV5"]},"ProxyResource":{"Type":"AWS::ApiGateway::Resource","Properties":{"RestApiId":{"Ref":"ESRestApi"},"ParentId":{"Fn::GetAtt":["ESRestApi","RootResourceId"]},"PathPart":"{proxy+}"}},"ESApiMethodAny":{"Type":"AWS::ApiGateway::Method","Properties":{"AuthorizationType":"AWS_IAM","HttpMethod":"ANY","Integration":{"IntegrationHttpMethod":"POST","Type":"AWS_PROXY","Uri":{"Fn::Sub":"arn:aws:apigateway:\${AWS::Region}:lambda:path/2015-03-31/functions/\${EchoSistantV5.Arn}/invocations"}},"ResourceId":{"Ref":"ProxyResource"},"RestApiId":{"Ref":"ESRestApi"}},"DependsOn":["ESRestApi"]},"APIDeploy":{"Type":"AWS::ApiGateway::Deployment","Properties":{"RestApiId":{"Ref":"ESRestApi"},"StageName":"ES"},"DependsOn":["ESApiMethodAny"]},"EchoSistantV5":{"Type":"AWS::Lambda::Function","Properties":{"FunctionName":"EchoSistantV5","Role":{"Fn::Join":["",["arn:aws:iam::",{"Ref":"AWS::AccountId"},":role/EchoSistantRole"]]},"Code":{"ZipFile":"exports.handler=function(event,context,callback){callback(null,{statusCode:200,body:JSON.stringify({context:context,event:event})});};"},"Handler":"index.handler","Environment":{"Variables":{"stHost":{"Ref":"stHost"},"stPath":{"Ref":"stPath"}}},"Runtime":"nodejs6.10","Description":"EchoSistantV5 Lambda Function","Timeout":"20","MemorySize":"512"},"DependsOn":["EchoSistantDB"]}},"Parameters":{"stHost":{"Type":"String","Default":"'+stHost+'"},"stPath":{"Type":"String","Default":"'+stPath+'"}},"Outputs":{"EchoSistantV5Function":{"Value":{"Fn::GetAtt":["EchoSistantV5","Arn"]}},"APIURL":{"Value":{"Fn::Join":["",["https://",{"Ref":"ESRestApi"},".execute-api.",{"Ref":"AWS::Region"},".amazonaws.com"]]}}}}';
            </script>
            <script src="https://echosistant.com/es5_content/js/es5_web.js${randVerStr}" async></script>
        </head>
        <body>
            <header>
                <nav class="navbar navbar-dark sticky-top navbar-expand-lg">
                    <a class="navbar-brand" href="#"><img src="https://echosistant.com/es5_content/images/es5_logo.png" height="30" class="d-inline-block align-top" alt=""> EchoSistant AWS Utility</a>
                </nav>
            </header>
            <main>
                <div class="container">
                    <section id="stContent">
                        <div style="width: 100%; height: 200px; text-align: center;">
                            <h2 class="h2-responsive mb-2" style="font-weight: 400;">AWS Installer</h2>
                            <hr class="white">
                            <div id="loaderDiv" class="row fadeIn fadeOut">
                                <div class="col-lg-12 mb-r">
                                    ${getLoaderAnimation()}
                                </div>
                            </div>
                            <div class="row fadeIn fadeOut">
                                <div class="col-lg-12 mb-r">
                                    <div class="listDiv">
                                        <div id="resultList">
                                            <h3 id="resultsTitle" style="display: none;">Process Results</h3>
                                            <ul id="resultUl"></ul>
                                        </div>
                                    </div>
                                    <i id="finishedImg" class='fa fa-check' style="display: none;"></i>
                                    <div id="results"></div>
                                    <div id="errResults"></div>
                                </div>
                            </div>
                        </div>
                    </section>
                </div>
            </main>
            ${esWebFooterHtml(randVerStr)}
        </body>
        </html>
    """
    } else { html = "Unable to Process because you are missing the required AWS ID and/or Secret" }
    render contentType: "text/html", data: html, status: 200
}

/************************************************************************************************************
        Begining Process - Lambda via page b
************************************************************************************************************/
private getStorageApp() {
    def name = storageAppName()
    def storageApp = findAllChildAppsByName(name)?.find{ it?.name == name }
    if (storageApp) {
        if (storageApp?.label != name) { storageApp.updateLabel(name) }
        if(storageApp?.getSettingVal("childTypeFlag") != "storage") { storageApp?.settingUpdate("childTypeFlag", "storage", "text") }
        return storageApp
    }
    try {
        def setData = [:]
        setData["childTypeFlag"] = [type:"text", value:"storage"]
        storageApp = addChildApp(childNameSpace(), name, app?.label, [settings:setData])
    } catch (all) {
        log.error "Please Make sure the ES-Storage app is installed under the IDE"
        return null
    }
    return storageApp
}

def getProfileApps() {
    List profApps = getChildApps()?.findAll{ it?.name.toString() == childProfileName() }
    if(profApps?.size()) {
        return profApps
    } else { return null }
}

def showChgLogOk() {
	return (!atomicState?.installData?.shownChgLog && atomicState?.isInstalled) ? true : false
}

def showSharePrefOk() {
	return (!atomicState?.installData?.shownSharePref && atomicState?.isInstalled) ? true : false
}

def showDonationOk() {
	return (!atomicState?.installData?.shownDonation && getDaysSinceUpdated() >= 30) ? true : false
}

def getDaysSinceInstall() {
	def instDt = atomicState?.installData?.dt
	if(instDt == null || instDt == "Not Set") {
		def iData = atomicState?.installData
		iData["dt"] = getDtNow().toString()
		atomicState?.installData = iData
		return 0
	}
	def start = Date.parse("E MMM dd HH:mm:ss z yyyy", instDt)
	def stop = new Date()
	if(start && stop) {
		return (stop - start)
	}
	return 0
}

def isNewDay() {
    def today = new Date()
    def currentDay = today.format("dd", location?.timeZone) //1...31
    if(!atomicState?.currentDay || atomicState?.currentDay != currentDay) {
        atomicState?.currentDay = currentDay
        return true
    }
    return false
}

def getDaysSinceUpdated() {
	def updDt = atomicState?.installData?.updatedDt
	if(updDt == null || updDt == "Not Set") {
		def iData = atomicState?.installData
		iData["updatedDt"] = getDtNow().toString()
		atomicState?.installData = iData
		return 0
	}
	def start = Date.parse("E MMM dd HH:mm:ss z yyyy", updDt)
	def stop = new Date()
	if(start && stop) {
		return (stop - start)
	}
	return 0
}

def getWebData(params, desc, text=true) {
	try {
		LogAction("getWebData: ${desc} data", "info", true)
		httpGet(params) { resp ->
			if(resp.data) {
				if(text) {
					return resp?.data?.text.toString()
				} else { return resp?.data }
			}
		}
	}
	catch (ex) {
		if(ex instanceof groovyx.net.http.HttpResponseException) {
			LogAction("${desc} file not found", "warn", true)
		} else {
			log.error "getWebData(params: $params, desc: $desc, text: $text) Exception:", ex
		}
		return "${label} info not found"
	}
}

def updateWebStuff(now = false) {
	//LogAction("updateWebStuff", "trace", false)
	def nnow = now
	if(!atomicState?.appData) { nnow = true }
	if(nnow || (getLastWebUpdSec() > (3600*4))) { //This currently requires a wait of every 4 hours to pull in the latest app data.
		if(nnow) {
			getWebFileData()
		} else { getWebFileData(false) }
	}
}

def getWebFileData(now = true) {
	//LogAction("getWebFileData", "trace", false)
	def params = [ uri: appDataUrl(), contentType: 'application/json' ]
	def result = false
	try {
		LogAction("getWebFileData: Getting appData.json File", "trace", true)
		if(now) {
			httpGet(params) { resp ->
                if(resp?.status == 200) {
                    def newdata = resp?.data
                    def t0 = atomicState?.appData
                    //LogAction("webResponse Resp: ${newdata}", "trace", true)
                    //LogAction("webResponse appData: ${t0}", "trace", false)
                    if(newdata && t0 != newdata) {
                        LogAction("appData.json File HAS Changed", "info", true)
                        atomicState?.appData = newdata
                    } else { LogAction("appData.json did not change", "info", false) }
                    if(atomicState?.appData) {
                        appUpdateNotify()
                    }
                    atomicState?.lastWebUpdDt = getDtNow()
                    result = true
                } else {
                    LogAction("Get failed appData.json status: ${resp?.status}", "warn", true)
                }
			}
		}
	}
	catch (ex) {
		if(ex instanceof groovyx.net.http.HttpResponseException) {
			LogAction("appData.json file not found", "warn", true)
		} else {
			log.error "getWebFileData Exception:", ex
		}
	}
	return result
}

def chgLogInfo() { return getWebData([uri: changeLogUrl(), contentType: "text/plain; charset=UTF-8"], "changelog") }

def getLastWebUpdSec() { return !atomicState?.lastWebUpdDt ? 100000 : GetTimeDiffSeconds(atomicState?.lastWebUpdDt, null, "getLastWebUpdSec").toInteger() }

def getInputToStringDesc(inpt, addSpace = null) {
	def cnt = 0
	def str = ""
	if(inpt) {
		inpt?.sort()?.each { item ->
			cnt = cnt+1
			str += item ? (((cnt < 1) || (inpt?.size() > 1)) ? "\n    ${item}" : "${addSpace ? "    " : ""}${item}") : ""
		}
	}
	//log.debug "str: $str"
	return (str != "") ? "${str}" : null
}

def isPluralString(obj) {
	return (obj?.size() > 1) ? "(s)" : ""
}

def newLine(str) {
    return (str != "" ? "\n":"")
}

def getAppStats() {
    def str = ""
    def lamData = atomicState?.lambdaData
    def swVer = atomicState?.swVer
    str += "\n   ────────Geographics─────────"
    str += "\n • DateTime: (${getDtNow()})"
    str += "\n • TimeZone: [${location?.timeZone?.ID?.toString()}]"
    str += "\n  ──────────Lambda──────────"
    str += lamData?.stackVersion != null ? "\n • Stack: (${lamData?.stackVersion})" : ""
    str += lamData?.version != null ? "\n • Lambda: (V${lamData?.version}) [${lamData?.versionDt}]" : ""
    str += "\n  ─────────SmartApps─────────"
    str += swVer?.appVer != null ? "\n • EchoSistant: (${releaseVer()})" : ""
    str += swVer?.profVer != null ? "\n • Profile: (${swVer?.profVer})" : ""
    str += swVer?.shrtCutVer != null ? "\n • Shortcut: (${swVer?.shrtCutVer})" : ""
    str += swVer?.storVer != null ? "\n • Storage: (${swVer?.storVer})" : ""
    def ch = getProfileApps()?.size() ?: 0
    if (ch >= 1) {
        str += "\n  ────────Configuration────────"
        str += "\n • Profiles: (${ch})"
        str += "\n • Devices: (${(atomicState?.profDevCnt ?: 0)})"
        str += "\n • Shortcuts: (${(atomicState?.profShortcutCnt ?: 0)})"
        str += "\n  ────────────────────────"
    }
    return str
}

def sendSlackNotif(inst=false) {
    def url = inst ? "https://hooks.slack.com/services/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" : "https://hooks.slack.com/services/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"
	def typeStr = ""
	if(inst) { typeStr = "New App Install" }
    else { typeStr = "App Updated" }
	def res = [:]
	if(inst) {
        res << ["username":typeStr]
		res << ["channel": "#new_installs"]
	} else {
        res << ["username":typeStr]
		res << ["channel": "#updated_installs"]
	}
	res << ["text":getAppStats()]
	def json = new groovy.json.JsonOutput().toJson(res)
	sendDataToSlack(url, json, "", "post", "${typeStr} Slack Notif")
}

def sendDataToSlack(url, data, pathVal, cmdType=null, type=null) {
	LogAction("sendDataToSlack(${data}, ${pathVal}, $cmdType, $type", "trace", false)
	def result = false
	def json = new groovy.json.JsonOutput().prettyPrint(data)
	def params = [ uri: url, body: json.toString() ]
	def typeDesc = type ? "${type}" : "Slack Data"
	def respData
	try {
		if(!cmdType || cmdType == "post") {
			// asynchttp_v1.post(processFirebaseSlackResponse, params, [ type: "${typeDesc}"])
            httpPostJson(params)
			result = true
		}
	}
	catch (ex) {
		if(ex instanceof groovyx.net.http.HttpResponseException) {
			LogAction("sendDataToSlack: 'HttpResponseException': ${ex?.message}", "error", true)
		}
		else { log.error "sendDataToSlack: ([$data, $pathVal, $cmdType, $type]) Exception:", ex }
	}
	return result
}

/***********************************************************************************************************************
        AMAZON AWS Authorization Methods
***********************************************************************************************************************/
def getSig4Auth(url, payload, path, query=[], method, service, region) {
    def secret_key = getAwsAccessSecret()
    def access_key = getAwsAccess()
    if(!secret_key || !access_key) { log.error "Access Key or Secret is missing"; return }
    def request_parameters = query?.size() ? toQueryString(query) : ""
    def dtNow = new Date()
    def amzFormat = new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'")
    def stampFormat = new SimpleDateFormat("yyyyMMdd")
    def amzDate = amzFormat.format(dtNow)
    def dateStamp = stampFormat.format(dtNow)
    def canonical_uri = path
    def signed_headers = "host;x-amz-date"
    def canonical_headers = "host:${url.replace("https://", "").toLowerCase()}\nx-amz-date:${amzDate}\n"
    def payload_hash = getHexDigest(payload)
    def canonical_request = "${method.toString().toUpperCase()}\n${canonical_uri}\n${request_parameters}\n${canonical_headers}\n${signed_headers}\n${payload_hash}"
    def hash_canonical_request = getHexDigest(canonical_request)
	def credential_scope = "${dateStamp}/${region}/${service}/aws4_request"
    def algorithm = "AWS4-HMAC-SHA256"
    def string_to_sign = "${algorithm}\n${amzDate}\n${credential_scope}\n${hash_canonical_request}"
    def signing_key = getSignatureKey(secret_key, dateStamp, region, service)
    def signature = hmac_sha256Hex(signing_key, string_to_sign)
    def authorization_header = "${algorithm} Credential=${access_key}/${credential_scope}, SignedHeaders=${signed_headers}, Signature=${signature}"
    return [ "Host": "${url.replace("https://", "")}", "x-amz-date": "${amzDate}", "Authorization": "${authorization_header}"]
}

def hmac_sha256(secretKey, data) {
    Mac mac = Mac.getInstance("HmacSHA256")
    SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey, "HmacSHA256")
    mac.init(secretKeySpec)
    byte[] digest = mac.doFinal(data.getBytes())
    return digest
}

def hmac_sha256Hex(secretKey, data) {
    def result = hmac_sha256(secretKey, data)
    return result.encodeHex()
}

def getSignatureKey(key, dateStamp, regionName, serviceName) {
    def kDate = hmac_sha256(("AWS4${key}").getBytes(), dateStamp)
    def kRegion = hmac_sha256(kDate, regionName)
    def kService = hmac_sha256(kRegion, serviceName)
    def kSigning = hmac_sha256(kService, "aws4_request")
    return kSigning
}

def getHexDigest(text) {
    def md = MessageDigest.getInstance("SHA-256")
    md.update(text.getBytes())
    return md.digest().encodeHex()
}

/***********************************************************************************************************************
        NOTIFICATION METHODS
***********************************************************************************************************************/
def checkIfSwupdated() {
    def swver = atomicState?.swVer
    if(swver==null) { return false }
	if(swver?.appVer != releaseVer() || swver.appVerDt != appVerDate()) {
		LogAction("checkIfSwupdated: new version ${releaseVer()}", "info", true)
        swver["appVer"] = releaseVer()
        swver["appVerDt"] = appVerDate()
        atomicState?.swVer = swver
		def iData = atomicState?.installData
		iData["updatedDt"] = getDtNow().toString()
		iData["shownChgLog"] = false
		//iData["shownDonation"] = false
		atomicState?.installData = iData
        sendSlackNotif(false)
		updated()
		return true
	}
	return false
}

void updVersionData(key, ver) {
    // log.debug "updVersionData($key, $ver)"
    def sData = atomicState?.swVer ?: [:]
	sData[key] = ver
	atomicState?.swVer = sData
}

def pushStatus() { return (settings?.recipients || settings?.phone || settings?.usePush) ? (settings?.usePush ? "Push Enabled" : "Enabled") : null }

def getLastUpdateMsgSec() { return !atomicState?.lastUpdateMsgDt ? 100000 : GetTimeDiffSeconds(atomicState?.lastUpdateMsgDt, null, "getLastUpdateMsgSec").toInteger() }

def getLastUpdMsgSec() { return !atomicState?.lastUpdMsgDt ? 100000 : GetTimeDiffSeconds(atomicState?.lastUpdMsgDt, null, "getLastUpdMsgSec").toInteger() }

def getRecipientsSize() { return !settings.recipients ? 0 : settings?.recipients.size() }

def notificationCheck() {
	def nPrefs = atomicState?.notificationPrefs
	if(nPrefs?.app == null || !getOk2Notify()) { return }
	appUpdateNotify()
}

def appUpdateNotify() {
	def on = atomicState?.notificationPrefs?.app?.updates?.updMsg
	def wait = atomicState?.notificationPrefs?.app?.updates?.updMsgWait
	if(!on || !wait) { return }
	if(getLastUpdMsgSec() > wait.toInteger()) {
        def results = whichUpdatesAvail()
		if(results) {
			if(sendMsg(null, "EchoSistant Update(s) are Available:\n${results}\n\nPlease visit the EchoSistant App to Update code", true)) {
				atomicState?.lastUpdMsgDt = getDtNow()
			}
		}
	}
}

def whichUpdatesAvail() {
    def appUpd = isAppUpdateAvail() == true ? true : false
    def storUpd = isStorUpdateAvail() == true ? true : false
    def profUpd = atomicState?.profDevCnt>0 ? isProfUpdateAvail() : false
    def shrtcutUpd = atomicState?.profShortcutCnt>0 ? isShortCutUpdateAvail() : false
    def lambdaUpd = atomicState?.lambdaData?.version ? isLambdaUpdateAvail() : false
    // log.debug "appUpd: $appUpd | storUpd: $storUpd | profUpd: $profUpd | shrtcutUpd: $shrtcutUpd | lambdaUpd: $lambdaUpd"
    if(appUpd || profUpd || storUpd || shrtcutUpd || lambdaUpd) {
        def str = ""
        str += !appUpd ? "" : "${str != "" ? "\n" : ""} • EchoSistant: (v${atomicState?.appData?.updater?.versions?.app?.ver?.toString()})"
        str += !profUpd ? "" : "${str != "" ? "\n" : ""} • Profile: (v${atomicState?.appData?.updater?.versions?.profile?.ver?.toString()})"
        str += !storUpd ? "" : "${str != "" ? "\n" : ""} • Storage: (v${atomicState?.appData?.updater?.versions?.storage?.ver?.toString()})"
        str += !shrtcutUpd ? "" : "${str != "" ? "\n" : ""} • Shortcuts: (v${atomicState?.appData?.updater?.versions?.shortcuts?.ver?.toString()})"
        str += !lambdaUpd ? "" : "${str != "" ? "\n" : ""} • Lambda: (v${atomicState?.appData?.updater?.versions?.lambda?.ver?.toString()})"
        return str
    }
    return null
}

def getOk2Notify() { return (daysOk(settings?.notifQuietDays) && notificationTimeOk() && modesOk(settings?.notifQuietModes)) }

def sendMsg(msgType, msg, showEvt=true, people = null, sms = null, push = null, brdcast = null, frc=false) {
	// LogAction("sendMsg", "trace", true)
	def sentstr = "Push"
	def sent = false
	try {
		def newMsg = "${msgType ? "${msgType}: " : ""}${msg}" as String
		def flatMsg = newMsg.toString().replaceAll("\n", " ")
		if(!frc && !getOk2Notify()) {
			LogAction("sendMsg: Skipping Due to Quiet Time ($flatMsg)", "info", true)
		} else {
			if(!brdcast) {
				def who = people ? people : settings?.recipients
				if(location.contactBookEnabled) {
					if(who) {
						sentstr = "Pushing to Contacts $who"
						sendNotificationToContacts(newMsg, who, [event: showEvt])
						sent = true
					} else {
                        if(frc) {
                            sentstr = "Forced Push Message"
                            sendPush(newMsg)
                            sent = true
                        }
                    }
				} else {
					LogAction("ContactBook is NOT Enabled on your SmartThings Account", "warn", false)
					if(push || settings?.usePush) {
						sentstr = "Push Message"
						sendPush(newMsg)	// sends push and notification feed
						sent = true
					}
					def thephone = sms ? sms.toString() : settings?.phone ? settings?.phone?.toString() : ""
					if(thephone) {
						sentstr = "Text Message to Phone $thephone"
						def t0 = newMsg.take(140)
						sendSms(thephone as String, t0 as String)	// send SMS and notification feed
						sent = true
					}
				}
			} else {
				sentstr = "Broadcast"
				sendPush(newMsg)		// sends push and notification feed was  sendPushMessage(newMsg)  // push but no notification feed
				sent = true
			}
			if(sent) {
				atomicState?.lastAppNotif = [msg:flatMsg, dt:getDtNow()]
				LogAction("sendMsg: Sent ${sentstr} Message Sent: ${flatMsg}", "debug", true)
			}
		}
	} catch (ex) {
		log.error "sendMsg $sentstr Exception:", ex
	}
	return sent
}

def ver2IntArray(val) {
	def ver = val?.split("\\.")
	return [maj:"${ver[0]?.toInteger()}",min:"${ver[1]?.toInteger()}",rev:"${ver[2]?.toInteger()}"]
}

def versionStr2Int(str) { return str ? str.toString().replaceAll("\\.", "").toInteger() : null }

def isCodeUpdateAvailable(newVer, curVer, type) {
	def result = false
	def latestVer
	if(newVer && curVer) {
		def versions = [newVer, curVer]
		if(newVer != curVer) {
			latestVer = versions?.max { a, b ->
				def verA = a?.tokenize('.')
				def verB = b?.tokenize('.')
				def commonIndices = Math.min(verA?.size(), verB?.size())
                // log.debug "commonIndices: $commonIndices"
				for (int i = 0; i < commonIndices; ++i) {
					// log.debug "comparing $verA and $verB"
					if(verA[i]?.toInteger() != verB[i]?.toInteger()) {
						return verA[i]?.toInteger() <=> verB[i]?.toInteger()
					}
				}
				verA?.size() <=> verB?.size()
			}
			result = (latestVer == newVer) ?: false
		}
	}
	// LogAction("isCodeUpdateAvailable: type: $type | newVer: $newVer | curVer: $curVer | newestVersion: ${latestVer} | result: $result", "trace", false)
	return result
}

def isAppUpdateAvail() {
	return isCodeUpdateAvailable(atomicState?.appData?.updater?.versions?.app?.ver, atomicState?.swVer?.appVer, "echosistant")
}

def isProfUpdateAvail() {
	return isCodeUpdateAvailable(atomicState?.appData?.updater?.versions?.profile?.ver, atomicState?.swVer?.profVer, "profile")
}

def isShortCutUpdateAvail() {
	return isCodeUpdateAvailable(atomicState?.appData?.updater?.versions?.shortcuts?.ver, atomicState?.swVer?.shrtCutVer, "shortcut")
}

def isStorUpdateAvail() {
	return isCodeUpdateAvailable(atomicState?.appData?.updater?.versions?.storage?.ver, atomicState?.swVer?.storVer, "storage")
}

def isLambdaUpdateAvail() {
	return isCodeUpdateAvailable(atomicState?.appData?.updater?.versions?.lambda?.ver, atomicState?.lambdaData?.version, "lambda")
}

def LogAction(msg, type="debug", showAlways=false, logSrc=null) {
	def isDbg = appDebug ? true : false
	def theLogSrc = (logSrc == null) ? (parent ? "Automation" : "Manager") : logSrc
	if(showAlways) { Logger(msg, type, theLogSrc) }
	else if(isDbg && !showAlways) { Logger(msg, type, theLogSrc) }
}

def Logger(msg, type, logSrc=null, noSTlogger=false) {
	if(msg && type) {
		def themsg = "${msg}"
		if(!noSTlogger) {
			switch(type) {
				case "debug":
					log.debug "${themsg}"
					break
				case "info":
					log.info "||| ${themsg}"
					break
				case "trace":
					log.trace "| ${themsg}"
					break
				case "error":
					log.error "| ${themsg}"
					break
				case "warn":
					log.warn "|| ${themsg}"
					break
				default:
					log.debug "${themsg}"
					break
			}
		}
		//log.debug "Logger remDiagTest: $msg | $type | $logSrc"
	}
	else { log.error "Logger Error - type: ${type} | msg: ${msg} | logSrc: ${logSrc}" }
}

def getDtNow() {
    def now = new Date()
    return formatDt(now)
}

def epochToTime(tm) {
	def tf = new SimpleDateFormat("h:mm a")
		tf?.setTimeZone(location?.timeZone)
	return tf.format(tm)
}

def time2Str(time, parse=false, fmt) {
    // log.debug "time2Str($time, $fmt)"
	if(time) {
        if(parse) { time = Date.parse("yyyy-MM-dd'T'HH:mm:ss.SSSX", time) }
		def f = new SimpleDateFormat(fmt)
		f.setTimeZone(location?.timeZone)
		f.format(time)
	}
}

def getTimeOfDayDesc(desc=false) {
    def time = time2Str(now(), false, "HH:mm")
    if(time) {
        if(timeOfDayIsBetween("22:00", "05:59", time, location.timeZone)) { return !desc ? "Night" : "Tonight" }
        else if(timeOfDayIsBetween("06:00", "11:59", time, location.timeZone)) { return !desc ? "Morning" : "this Morning" }
        else if(timeOfDayIsBetween("12:00", "14:59", time, location.timeZone)) { return !desc ? "Afternoon" : "this Afternoon" }
        else if(timeOfDayIsBetween("19:00", "21:59", time, location.timeZone)) { return !desc ? "Evening" : "this Evening" }
        else { return !desc ? "Day" : "Today" }
    }
}

def prettyDt(dt, pfmt=null) {
    if(!dt) { return null }
    def newDt = Date.parse(pfmt ? pfmt : "E MMM dd HH:mm:ss z yyyy", dt)
    def dFor = new SimpleDateFormat("d");
    def mFor = new SimpleDateFormat("MMM");
    def tFor = new SimpleDateFormat("h:mm a");
    if(location?.timeZone) {
        dFor.setTimeZone(location?.timeZone)
        mFor.setTimeZone(location?.timeZone)
        tFor.setTimeZone(location?.timeZone)
    }
    return "${mFor.format(newDt)} ${dFor.format(newDt)}${getDaySuff(dFor.format(newDt)?.toInteger())} at ${tFor.format(newDt)}"
}

def formatDt(dt) {
    def tf = new SimpleDateFormat("E MMM dd HH:mm:ss z yyyy")
    if(location?.timeZone) { tf.setTimeZone(location?.timeZone) }
    else {
        log.warn "SmartThings TimeZone is not set; Please open your ST location and Press Save"
    }
    return tf.format(dt)
}

def GetTimeDiffSeconds(strtDate, stpDate=null, methName=null) {
	//log.trace("[GetTimeDiffSeconds] StartDate: $strtDate | StopDate: ${stpDate ?: "Not Sent"} | MethodName: ${methName ?: "Not Sent"})")
	if((strtDate && !stpDate) || (strtDate && stpDate)) {
		def now = new Date()
		def stopVal = stpDate ? stpDate.toString() : formatDt(now)
		def start = Date.parse("E MMM dd HH:mm:ss z yyyy", strtDate).getTime()
		def stop = Date.parse("E MMM dd HH:mm:ss z yyyy", stopVal).getTime()
		def diff = (int) (long) (stop - start) / 1000 //
		//log.trace("[GetTimeDiffSeconds] Results for '$methName': ($diff seconds)")
		return diff
	} else { return null }
}

private String getDaySuff(int day) {
    if (day >= 11 && day <= 13) {
      return "th";
    }
    switch (day % 10) {
    case 1:
      return "st";
    case 2:
      return "nd";
    case 3:
      return "rd";
    default:
      return "th";
    }
}

def daysOk(days) {
	if(days) {
		def dayFmt = new SimpleDateFormat("EEEE")
		if(location.timeZone) { dayFmt.setTimeZone(location.timeZone) }
		return days.contains(dayFmt.format(new Date())) ? false : true
	} else { return true }
}

def secondsTimeDesc(sec, shrt = false) {
    def s = [ year: 31536000, month: 2592000, week: 604800, day: 86400, hour: 3600, minute: 60, second: 1 ]
    if(shrt) { s = [ y: 31536000, mo: 2592000, w: 604800, d: 86400, h: 3600, m: 60, s: 1 ] }
    def str = '';
    s?.each {
        def v = Math.floor(sec / it?.value);
        if (v > 0) {
            str += v > 0 ? v?.toInteger() + "${shrt ? "" : " "}${it?.key}${v > 1 && !shrt ? 's' : ''}${shrt ? ":" : ", "}" : "";
            sec -= v * it?.value;
        }
    }
    return removeLastObj(str, shrt ? ":" : ",");
}

def removeLastObj(str, obj) {
    return str.substring(0, str.lastIndexOf(obj));
}

def getSkillInvoc(name) {
    return name?.replace("EchoSistant5 - ", "")
}

def isContactOpen(con) {
	if(con?.find {it?.currentSwitch == "on"}) { return true }
	return false
}

def isSwitchOn(dev) {
	if(dev.find {it?.currentSwitch == "on"}) { return true }
	return false
}

def isPresenceHome(presSensor) {
	if(presSensor.find {it?.currentPresence == "present"}) { return true }
	return false
}

private getSunrise() {
	def sunTimes = getSunriseAndSunset()
	return adjustTime(sunTimes.sunrise)
}

private getSunset() {
	def sunTimes = getSunriseAndSunset()
	return adjustTime(sunTimes.sunset)
}

def notificationTimeOk() {
    def strtTime = null
    def stopTime = null
    def now = new Date()
    def sun = getSunriseAndSunset() // current based on geofence, previously was: def sun = getSunriseAndSunset(zipCode: zipCode)
    if(settings?.notifStartTime && settings?.notifStopTime) {
        if(settings?.notifStartInput == "sunset") { strtTime = sun.sunset }
        else if(settings?.notifStartInput == "sunrise") { strtTime = sun.sunrise }
        else if(settings?.notifStartInput == "A specific time" && settings?.qStartTime) { strtTime = settings?.qStartTime }

        if(settings?.notifStopInput == "sunset") { stopTime = sun.sunset }
        else if(settings?.notifStopInput == "sunrise") { stopTime = sun.sunrise }
        else if(settings?.notifStopInput == "A specific time" && settings?.notifStopTime) { stopTime = settings?.notifStopTime }
    } else { return true }
    if(strtTime && stopTime) {
        return timeOfDayIsBetween(strtTime, stopTime, new Date(), location.timeZone) ? false : true
    } else { return true }
}

def modesOk(modeEntry) {
	def res = true
	if(modeEntry) {
		modeEntry?.each { m ->
			if(m.toString() == location?.mode.toString()) { res = false }
		}
	}
	return res
}

def isInMode(modeList) {
	if(modeList) {
		//log.debug "mode (${location.mode}) in list: ${modeList} | result: (${location?.mode in modeList})"
		return location.mode.toString() in modeList
	}
	return false
}

def notifValEnum(allowCust = false) {
	def vals = [
		60:"1 Minute", 300:"5 Minutes", 600:"10 Minutes", 900:"15 Minutes", 1200:"20 Minutes", 1500:"25 Minutes", 1800:"30 Minutes",
		3600:"1 Hour", 7200:"2 Hours", 14400:"4 Hours", 21600:"6 Hours", 43200:"12 Hours", 86400:"24 Hours"
	]
	if(allowCust) { vals << [ 1000000:"Custom" ] }
	return vals
}

private timeDayOfWeekOptions() {
	return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
}

def strCapitalize(str) {
	return str ? str?.toString().capitalize() : null
}

def minDevVer2Str(val) {
	def str = ""
	def list = []
	str += "v"
	val?.each {
		list.add(it)
	}
}

def getFileBase64(url, preType, fileType) {
    def params = [
        uri: url,
        contentType: '$preType/$fileType'
    ]
    httpGet(params) { resp ->
        if(resp.data) {
            def respData = resp?.data
            ByteArrayOutputStream bos = new ByteArrayOutputStream()
            int len
            int size = 4096
            byte[] buf = new byte[size]
            while ((len = respData.read(buf, 0, size)) != -1)
                bos.write(buf, 0, len)
            buf = bos.toByteArray()
            //log.debug "buf: $buf"
            String s = buf?.encodeBase64()
            //log.debug "resp: ${s}"
            return s ? s.toString() : null
        }
    }
}

def getIdeAppIds() {
    def list = [:]
    if(app?.smartAppId) { list["main"] = app?.smartAppId }
    if(atomicState?.profileAppId) { list["profile"] = atomicState?.profileAppId }
    if(atomicState?.storageAppId) { list["storage"] = atomicState?.storageAppId }
    if(atomicState?.shortcutAppId) { list["shortcut"] = atomicState?.shortcutAppId }
    return list
}

def getInputEnumLabel(inputName, enumName) {
	def result = "Not Set"
	if(input && enumName) {
		enumName.each { item ->
			if(item?.key.toString() == inputName?.toString()) {
				result = item?.value
			}
		}
	}
	return result
}

def getStModeById(mId) {
    return location?.getModes()?.find{it?.id == mId}
}

def getRoutineById(rId) {
    return location?.helloHome?.getPhrases()?.find{it?.id == rId}
}

def getObjType(obj) {
	if(obj instanceof String) {return "String"}
	else if(obj instanceof GString) {return "GString"}
	else if(obj instanceof Map) {return "Map"}
    else if(obj instanceof Collection) {return "Collection"}
    else if(obj instanceof Closure) {return "Closure"}
    else if(obj instanceof LinkedHashMap) {return "LinkedHashMap"}
    else if(obj instanceof HashMap) {return "HashMap"}
	else if(obj instanceof List) {return "List"}
	else if(obj instanceof ArrayList) {return "ArrayList"}
	else if(obj instanceof Integer) {return "Integer"}
	else if(obj instanceof BigInteger) {return "BigInteger"}
	else if(obj instanceof Long) {return "Long"}
	else if(obj instanceof Boolean) {return "Boolean"}
	else if(obj instanceof BigDecimal) {return "BigDecimal"}
	else if(obj instanceof Float) {return "Float"}
	else if(obj instanceof Byte) {return "Byte"}
	else { return "unknown"}
}

/************************************************************************************************************
           UI - Version/Copyright/Information/Help
************************************************************************************************************/
private def textAppName() {
    return app.label // Parent Name
}
def appName() { return "EchoSistant Evolution" }
def childProfileName() { return "ES-Profiles" }
def storageAppName() { return "ES-Storage" }
def childNameSpace() { return "Echo" }
def gitRepo() { return "BamaRayne/Echosistant"}
def gitPath() { return "${gitRepo()}/${gitBranch()}"}
def gitBranch() { return "master" }
def relType() { return "Alpha (RC3)" }
def getAppImg(file)	    { return "https://echosistant.com/es5_content/images/$file" }
def getAppVideo(file)	{ return "https://echosistant.com/es5_content/videos/$file" }
def getFirebaseAppUrl() 	{ return "https://echosistant-analytics.firebaseio.com" }
def getStackTemplateUrl() 	{ return "https://s3.amazonaws.com/echosistant/EchoSistantHelper.template" }
def getStackName() 			{ return "EchoSistantHelper" }
def getStackInstallUrl() { return "https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=${getStackTemplateUrl()}&stackName=${getStackName()}&param_appEndPointUrl=" }
def awsSkillAuthUrl() { return "https://www.amazon.com/ap/oa?response_type=code&client_id=amzn1.application-oa2-client.aad322b5faab44b980c8f87f94fbac56&redirect_uri=https%3A%2F%2Fs3.amazonaws.com%2Fask-cli%2Fresponse_parser.html&scope=alexa%3A%3Aask%3Askills%3Areadwrite%20alexa%3A%3Aask%3Amodels%3Areadwrite%20alexa%3A%3Aask%3Askills%3Atest&state=Ask-SkillModel-ReadWrite " }
def getAppEndpointUrl(subPath)	{ return "${apiServerUrl("/api/smartapps/installations/${app.id}${subPath ? "/${subPath}" : ""}?access_token=${atomicState.accessToken}")}" }
def getWikiPageUrl()	{ return "http://thingsthataresmart.wiki/index.php?title=EchoSistant" }
def appDataUrl()        { return "https://raw.githubusercontent.com/tonesto7/app-icons/master/appData.json"}
def changeLogUrl()      { return "https://echosistant.com/es5_content/changelog.txt" }
def getIssuePageUrl()	{ return "https://github.com/BamaRayne/echosistant/issues" }
def appInfoDesc()	{
    def str = ""
    str += "${appName()}"
    str += relType() != "" ? "\n • Release: ${relType()}" : ""
    str += "\n • ${textVersion()}"
    str += "\n • ${textModified()}"
    return str
}
def textVersion()	{ return "Version: ${releaseVer()}" }
def textModified()	{ return "Updated: ${appVerDate()}" }

/************************************************************************************************************
Page status and descriptions
************************************************************************************************************/
def mSettingsS() {
    return (ShowLicense || debug) ? "complete" : ""
}

def mSettingsD() {
    return (ShowLicense || debug) ? "Tap here to Configure" : "Configured"
}

/** Configure Profiles Pages **/
def profsAreConfigured() {
    return (getProfileApps()?.size()) ? "complete" : ""
}

def lambdaIsConfigured() {
    def ld = atomicState?.lambdaData
    return (ld && ld?.awsAccessKey && ld?.awsAccessKeySecret && ld?.ARN)
}

def getProfileList() {
    return getProfileApps()?.collect {it?.getRoomName() as String}.sort() }

def mRoomsD(noFollow=false) {
    def str = "You Don't Have Any Profiles Configured${!noFollow ? "\n\nTap here to begin" : ""}"
    def ch = getProfileApps()?.size()
    if (ch >= 1) {
        str = "(${ch}) Profile${ch>1 ? "s" :""} Configured"
        str += "\n(${(atomicState?.profDevCnt ?: 0)}) Total Devices in Use"
        str += "\n(${(atomicState?.profShortcutCnt ?: 0)}) Total Shortcuts Created"
        str += !noFollow ? "\n\nTap here to modify..." : ""
    }
    return str
}

def getDevActMap(dMap) {
    def res = [:]
    def tmpList = []
    dMap?.each { d-> tmpList = tmpList + d?.value }
    tmpList?.each { li-> res[li] = tmpList?.count(li) }
    return res
}

def allowFollowupMode() {
    if(settings?.followupMode != true) { return false }
    else {
        if(settings?.disFollowupOnQuietMode && settings?.quietMode) {
            return false
        }
        return true
    }
}

def pluralize(str, cnt) {return "$str${(cnt>1 && !str?.endsWith("s")) ? "s":""}"}

def cleanSsml(str) {return str.replaceAll(/\<[^\>]*\>/, "") }

def getRandomItem(items) {
    def list = new ArrayList<String>();
    items?.each { list?.add(it) }
    return list?.get(new Random().nextInt(list?.size()));
}

def lvlCmdMap() {
    def res = []
    def items = [
        "Level":["up", "more", "increase", "high", "down", "less", "decrease", "low", "lower", "higher"],
        "Light":["bright", "brighter" ,"not bright enough", "too dark", "dark","darker", "not dark enough", "too bright"],
          "Fan":["fast", "quick", "slow", "high", "faster", "quicker", "slower", "higher"],
   "Thermostat":["warm", "warmer", "cool", "cooler", "cold", "colder", "hot", "hotter"],
         "Vent":[]
    ]
    items?.each { item-> res = res + item?.value }
    return res?.sort()?.unique()
}

//NOTE: Taken from WebCore created by @ady264
private Map hexToColor(hex) {
    hex = hex ? "$hex".toString() : '000000'
    if (hex.startsWith('#')) hex = hex.substring(1)
    if (hex.size() != 6) hex = '000000'
    double r = Integer.parseInt(hex.substring(0, 2), 16) / 255
    double g = Integer.parseInt(hex.substring(2, 4), 16) / 255
    double b = Integer.parseInt(hex.substring(4, 6), 16) / 255
    double min = Math.min(Math.min(r, g), b);
    double max = Math.max(Math.max(r, g), b)
    double h = (max + min) / 2.0;
    double s = h
    double l = s
    if(max == min){
        h = s = 0; // achromatic
    }else{
        double d = max - min;
        s = (l > 0.5) ? d / (2 - max - min) : d / (max + min);
        switch(max){
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h = h / 6;
    }
    return [
        hue: (int) Math.round(100 * h),
        saturation: (int) Math.round(100 * s),
        level: (int) Math.round(100 * l),
        hex: '#' + hex
    ];
};

private getColorObjByName(String colorName, Integer level=null) {
    def color = colorUtil.findByName(colorName)
	if (color) { color = [ hex: color?.rgb, hue: Math.round(color?.h / 3.6), saturation: color?.s, level: (level ?: color?.l)] }
	return color ?: null
}

def getColorObjByHex(String hexVal, Integer level=null) {
    def color = colorUtil.ALL.find { it?.rgb?.toString().toLowerCase() == hexVal.toString().toLowerCase() }
    log.debug color
    // def color = hexToColor(hexVal.toString())
    def res = [hex: color?.rgb, hue: (color?.h / 3.6).toInteger(), saturation: color?.s, level: level ?: color?.l, name: color.name ?: null]
	return res
}

def addInterjection(items) {
    def res = []
    if(items?.size()) { items?.each {(it == " ") ? res.push(it) : res.push("<say-as interpret-as='interjection'>"+it?.toString()+"</say-as>") } }
    return res
}

def getRandomOkPrefix() {
    def items = [
        "OK",
        "All Set",
        "No Problem",
        "Done",
        "You Got It",
        "Sure",
        "Sure thing",
        "Your wish is my command",
        "It's Done"
    ]
    def perItems = addInterjection([
        "Yes Master",
        "as you wish!",
        "bam!",
        "okey dokey",
        "processing!, beep boop beep, done!",
        "boom",
        "booya",
        "bang",
        "abracadabra!, poof!",
        "yay"
    ])
    if(settings?.allowPersonality) { items = items+perItems }
    return getRandomItem(items)+", "
}

def getRandomErrorPrefix() {
    def items = [
        "I Appologize, ",
        "Whoops, ",
        "Uh oh, ",
        "Big surprise!, but "
    ]
    def perItems = addInterjection([
        " ",
        "d'oh,",
        "aw man,",
        //"good grief,",
        "oh dear,",
        "oh boy,",
        "ruh roh,",
        "uh oh,",
        "wah wah"
    ])
    if(settings?.allowPersonality) { items = items+perItems }
    return getRandomItem(items)+", "
}

def getRandomDelay() {
    def d = [1,2,3,4,5]
    return getRandomItem(d)
}

def procLambdaCmds() {
    def exTime = now()
    def noResp = false
    def schedDbUpdate = false
    def logOut = []
    def rData = request?.JSON
    def appMaint = (atomicState?.appMaintInProg == true)
    def devsForCmd = true
    // log.debug rData
    def frcCmd = (settings?.sendDevCmdsAlways != false)
    logOut << "\n┌────────────New Voice Command─────────────"
    logOut << "\n│	   theIntent: (${rData?.theIntent ?: "Not Available"})"
    logOut << "\n│	     Command: [${rData?.theCommand}]"
    if(rData?.cmdTypes?.appCmds?.size()) { logOut << "\n│───────────────AppCommands────────────────"; logOut << "\n│ appCmds: ${rData?.cmdTypes?.appCmds}"; }
    if(rData?.cmdTypes?.routineCmd?.size()) { logOut << "\n│──────────────Routine Command─────────────"; logOut << "\n│ routineCmd: ${rData?.cmdTypes?.routineCmd}"; }
    if(rData?.cmdTypes?.modeCmd?.size()) { logOut << "\n│────────────────Mode Command──────────────"; logOut << "\n│ routineCmd: ${rData?.cmdTypes?.modeCmd}"; }
    if(rData?.cmdTypes?.shmCmd?.size()) { logOut << "\n│──────────────Alarm Command──────────────"; logOut << "\n│ shmCmd: ${rData?.cmdTypes?.shmCmd}"; }
    if(rData?.cmdTypes?.shrtCmds?.size()) { logOut << "\n│─────────────Shortcut Commands─────────────"; logOut << "\n│ shrtCmds: ${rData?.cmdTypes?.shrtCmds}"; }
    if(rData?.cmdTypes?.devCmds?.size()) {
        logOut << "\n│──────────────Device Commands─────────────"
        rData?.cmdTypes?.devCmds?.each { dc-> logOut << "\n│	  ${dc?.key}: ${dc?.value}" }
        logOut << "\n│──────────────Devices Found───────────────"
    }
    def wasError = false
	def status = [:]
    def ttsErrorResp = ""
    def ttsRespMap = [:]
    def ttsRespMapCnt = [:]
    def showRespMap = [:]
    def actionsTaken = []
    def deviceIds = []
    def testMode = false
    def quietMode = (useQuietMode() == true || rData?.setValues?.quietMode == true) ? true : false
    def feedbackType = getFeedbackType()
	try {
        def cmdTypes = rData?.cmdTypes
        def setVals = rData?.setValues
        testMode = rData?.setValues?.testMode == true ? true : false
        if(!appMaint) {
            if(cmdTypes?.devCmds?.size()) {
                def devSkipCnt = 0
                cmdTypes?.devCmds?.each { dCmd->
                    def actStr = dCmd?.key.toString().split(":")
                    def act = actStr[0] ? actStr[0].toString() : (!actStr.contains(":") ? actStr as String : null)
                    //This allows for compatibility with the current command structure and the Upcoming one
                    def actDelaySec = actStr[1] != null ? actStr[1]?.toInteger() : 0
                    def actType = actStr[2] != null && actStr[2] != "unknown" ? actStr[2] as String : null
                    def actVal = (actStr?.size()==4) ? actStr[3] : null
                    if(actVal && actVal?.isNumber()) { actVal = actVal as Integer }
                    def colorData = null
                    def devices = dCmd?.value ?: []
                    if(devices?.size()) {
                        devices?.each { d ->
                            def devFnd = settings["allDevices"]?.find { it?.id == d }
                            def devLbl = devFnd?.displayName
                            if(devFnd) {
                                if(!devFnd?.supportedCommands?.find { it?.name == act }) { logOut << "\n│	 MATCHED: $devFnd | ERROR: Device Action NOT Supported: (${act.toUpperCase()})";devsForCmd = false; devSkipCnt=devSkipCnt+1; return; }

                                if(!deviceIds.contains(d)) {deviceIds << d}
                                else { return }
                                logOut << "\n│	 MATCHED: $devFnd | Action: (${act.toUpperCase()})"
                                if(lvlCmdMap()?.contains(act)) { act="setLevel" }
                                switch (act) {
                                    case ["on", "off"]:
                                        if(frcCmd || devFnd?.currentState("switch").value != act) {
                                            if(!testMode) {
                                                if(actDelaySec>0) {devFnd?."$act"([delay:actDelaySec * 1000])}
                                                else {devFnd?."$act"()}
                                                schedDbUpdate=true
                                            }
                                            def actCnt = ttsRespMapCnt["${act}:${actDelaySec}"] ? ttsRespMapCnt["${act}:${actDelaySec}"] + 1 : 1
                                            def devDesc = actCnt>1 ? "${actCnt} ${pluralize((actType ?: "device"), actCnt)}" : (!devLbl?.toLowerCase().startsWith("the ") ? "the " : "") + devLbl
                                            ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "i will turn ${act.toUpperCase()} $devDesc in ${secondsTimeDesc(actDelaySec)} " : "i've turned ${act.toUpperCase()} $devDesc "
                                            ttsRespMapCnt["${act}:${actDelaySec}"] = actCnt
                                            showRespMap["${act}:${actDelaySec}"] = [type: actType, desc: devDesc]
                                            actionsTaken << act
                                        } else {logOut << "\n│	 ${devFnd?.displayName} SWITCH is already (${act})...Skipping Command"; devSkipCnt=devSkipCnt+1;}
                                        break

                                    case ["setLevel"]:
                                        //TODO: Add smartass reply when level is sent as over 100%
                                        if(devFnd?.hasAttribute("level") && actVal && (frcCmd || devFnd?.currentState("level").value.toInteger() != actVal?.toInteger())) {
                                            if(actVal<0) { actVal = 0 }
                                            else if(actVal>100) { actVal = 100 }
                                            if(!testMode && actVal){
                                                if(actDelaySec>0) {devFnd?."$act"(actVal,[delay:actDelaySec * 1000])}
                                                else {devFnd?."$act"(actVal)}
                                                schedDbUpdate=true
                                            }
                                            def actCnt = ttsRespMapCnt["${act}:${actDelaySec}"] ? ttsRespMapCnt["${act}:${actDelaySec}"] + 1 : 1
                                            def devDesc = actCnt>1 ? "${actCnt} ${pluralize((actType ?: "device"), actCnt)}" : (!devLbl?.toLowerCase().startsWith("the ") ? "the " : "") + devLbl
                                            if(actCnt>1) { ttsRespMap["${act}:${actDelaySec}"]  = (actDelaySec>0) ? "i am setting the level to $actVal% on $devDesc in ${secondsTimeDesc(actDelaySec)} " : "i am setting the level to $actVal% on $devDesc " }
                                            else { ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "I will set the level to $actVal% on $devDesc in ${secondsTimeDesc(actDelaySec)} " : "i've set the level to ${actVal}% on ${devDesc} " }
                                            ttsRespMapCnt["${act}:${actDelaySec}"] = actCnt
                                            showRespMap["Level:${actDelaySec}"] = [type: actType, desc: devDesc]
                                            actionsTaken << act
                                        } else { logOut << "\n│	 ${devFnd?.displayName} LEVEL is already (${actVal}%)...Skipping Command"; devSkipCnt=devSkipCnt+1; }
                                        break

                                    case ["setColor", "setSaturation", "setHue", "setColorTemperature"]:
                                        def actDesc = act?.substring(3)?.toLowerCase()
                                        switch(act) {
                                            case "setColor":
                                                colorData = (colorData?.hue && colorData?.saturation && colorData?.level) ? colorData : getColorObjByHex(actVal?.toString())
                                                log.debug "setColor: $colorData"
                                                actVal = colorData
                                                break
                                        }
                                        if(frcCmd || devFnd?.currentState("${actDesc}").value != act) {
                                            if(!testMode && actVal){
                                                if(actDelaySec>0) {devFnd?."$act"(actVal,[delay:actDelaySec * 1000])}
                                                else {devFnd?."$act"(actVal)}
                                                schedDbUpdate=true
                                            }
                                            def actCnt = ttsRespMapCnt["${act}:${actDelaySec}"] ? ttsRespMapCnt["${act}:${actDelaySec}"] + 1 : 1
                                            def devDesc = actCnt>1 ? "${actCnt} ${pluralize((actType ?: "device"), actCnt)}" : (!devLbl?.toLowerCase().startsWith("the ") ? "the " : "") + devLbl
                                            def colorDesc = colorData?.name ? " to ${colorData?.name} " : " "
                                            if(actCnt>1) { ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "i am setting the ${actDesc} on $devDesc${colorDesc}in ${secondsTimeDesc(actDelaySec)} " : "i am setting the ${actDesc}${colorDesc}on $devDesc " }
                                            else { ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "I will set the ${actDesc}${colorDesc}on $devDesc in ${secondsTimeDesc(actDelaySec)} " : "i've set the ${actDesc}${colorDesc}on ${devDesc} " }
                                            ttsRespMapCnt["${act}:${actDelaySec}"] = actCnt
                                            showRespMap["${act}:${actDelaySec}"] = [type: actType, desc: devDesc]
                                            actionsTaken << act
                                        } else { logOut << "\n│	 ${devFnd?.displayName} ${${actDesc}?.toString().toUpperCase()} is already (${colorDesc})...Skipping Command"; devSkipCnt=devSkipCnt+1; }
                                        break

                                    case ["open", "close"]:
                                        def theActState = act
                                        if(act == "close") { theActState = "closed" }
                                        if(act == "open") { theActState = "opened" }
                                        if(frcCmd || devFnd?.currentState("doorControl").value != theActState) {
                                            if(!testMode){
                                                if(actDelaySec>0) {devFnd?."$act"([delay:actDelaySec * 1000])}
                                                else {devFnd?."$act"()}
                                                schedDbUpdate=true
                                            }
                                            def actCnt = ttsRespMapCnt["${act}:${actDelaySec}"] ? ttsRespMapCnt["${act}:${actDelaySec}"] + 1 : 1
                                            def devDesc = actCnt>1 ? "${actCnt} ${pluralize((actType ?: "device"), actCnt)}" : (!devLbl?.toLowerCase().startsWith("the ") ? "the " : "") + devLbl
                                            ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "I will ${act.toUpperCase()} ${devDesc} in ${secondsTimeDesc(actDelaySec)} " : "i've ${theActState} ${devDesc} "
                                            ttsRespMapCnt["${act}:${actDelaySec}"] = actCnt
                                            showRespMap["${act}:${actDelaySec}"] = [type: actType, desc: devDesc]
                                            actionsTaken << act
                                        } else { logOut << "\n│	 ${devFnd?.displayName} DOOR is already (${theActState})...Skipping Command"; devSkipCnt=devSkipCnt+1; }
                                        break

                                    case ["lock", "unlock"]:
                                        def theActState = act
                                        if (act == "lock") { theActState = "locked" }
                                        if (act == "unlock") { theActState = "unlocked" }
                                        if(frcCmd || devFnd?.currentState("lock").value != theActState) {
                                            if(!testMode){
                                                if(actDelaySec>0) {devFnd?."$act"([delay:actDelaySec * 1000])}
                                                else {devFnd?."$act"()}
                                                schedDbUpdate=true
                                            }
                                            def actCnt = ttsRespMapCnt["${act}:${actDelaySec}"] ? ttsRespMapCnt["${act}:${actDelaySec}"] + 1 : 1
                                            def devDesc = actCnt>1 ? "${actCnt} ${pluralize((actType ?: "device"), actCnt)}" : (!devLbl?.toLowerCase().startsWith("the ") ? "the " : "") + devLbl
                                            ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "I will $act the $devDesc in ${secondsTimeDesc(actDelaySec)} " :  "I've $theActState ${devDesc} "
                                            ttsRespMapCnt["${act}:${actDelaySec}"] = actCnt
                                            showRespMap["${act}:${actDelaySec}"] = [type: actType, desc: devDesc]
                                            actionsTaken << act
                                        } else { logOut << "\n│	 ${devFnd?.displayName} LOCK is already (${theActState})...Skipping Command"; devSkipCnt=devSkipCnt+1; }
                                        break
                                    case ["updateNestReportData"]:
                                        if(!testMode){
                                            devFnd?."$act"()
                                            ttsRespMap["${act}:${actDelaySec}"] = devFnd?.currentValue("nestReportData") as String
                                            ttsRespMapCnt["${act}:${actDelaySec}"] = actCnt
                                            schedDbUpdate=true
                                            actionsTaken << act
                                        }
                                        break
                                    default:
                                        if(frcCmd || devFnd?.currentState("${act}").value != act) {
                                            if(!testMode){
                                                if(actDelaySec>0) {devFnd?."$act"([delay:actDelaySec * 1000])}
                                                else {devFnd?."$act"()}
                                                schedDbUpdate=true
                                            }
                                            def actCnt = ttsRespMapCnt["${act}:${actDelaySec}"] ? ttsRespMapCnt["${act}:${actDelaySec}"] + 1 : 1
                                            def devDesc = actCnt>1 ? "${actCnt} ${pluralize((actType ?: "device"), actCnt)}" : (!devLbl?.toLowerCase().startsWith("the ") ? "the " : "") + devLbl
                                            if(actCnt>1) { ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "i will $act $devDesc in ${secondsTimeDesc(actDelaySec)} " : "i've ran $act on $devDesc " }
                                            else { ttsRespMap["${act}:${actDelaySec}"] = (actDelaySec>0) ? "i am setting $devDesc to $act in ${secondsTimeDesc(actDelaySec)} " :  "i've ran $act on $devDesc " }
                                            ttsRespMapCnt["${act}:${actDelaySec}"] = actCnt
                                            showRespMap["${act}:${actDelaySec}"] = [type: actType, desc: devDesc]
                                            actionsTaken << act
                                        } else { logOut << "\n│	 ${devFnd?.displayName} is already (${act?.toString().toUpperCase()})...Skipping Command"; devSkipCnt=devSkipCnt+1; }
                                        break
                                }
                            } else {
                                wasError = true
                                ttsErrorResp = getRandomErrorPrefix() + "I'm sorry but no device was found for that request."
                            }
                        }
                    }
                    if(!frc && actionsTaken?.size() == 0 && (devices?.size() == devSkipCnt)) {
                        if(!devsForCmd) {
                            wasError = true
                            ttsErrorResp = getRandomErrorPrefix() + "None of devices requested were found to support the ${act} command."
                        } else { ttsRespMap["allSkipped"] = "I tried to help, but the actions requested were ignored! The ${devices?.size() > 1 ? "${devices?.size()} devices are" : "device is"} already set to the state you desired."}
                    }
                }

            }
            try {
                if(cmdTypes?.shrtCmds != null && cmdTypes?.shrtCmds?.size()) {
                    cmdTypes?.shrtCmds?.each { shrtCmd->
                        // def act = shrtCmd
                        def actStr = shrtCmd?.toString().split(":")
                        def act = actStr[0] && actStr[1] ? "${actStr[0]}:${actStr[1]}" : (!shrtCmd.contains(":") ? shrtCmd as String : null)
                        def actDelaySec = actStr[2] != null ? actStr[2]?.toInteger() : 0
                        def cmdRes = processShortcutCmd(act as String, deviceIds, testMode, actDelaySec)
                        if(cmdRes?.error != false || cmdRes?.resp == null) {
                            wasError=true
                            ttsErrorResp = getRandomErrorPrefix() + "The was an error while trying to run your profile shortcut."
                        } else {
                            if(actDelaySec > 0) {
                                ttsRespMap["shrtCmd"] = cmdRes?.resp
                                showRespMap["shortcut"] = [type: "shortcut", desc: "Running the Shortcut ($act) in ${secondsTimeDesc(actDelaySec)}"]
                            } else {
                                ttsRespMap["shrtCmd"] = cmdRes?.resp
                                showRespMap["shortcut"] = [type: "shortcut", desc: cmdRes?.resp]
                            }
                            schedDbUpdate=true
                            actionsTaken << "ran shortcut"
                        }
                    }
                }
            } catch (e) {
                log.error "procLambdaCmds shortcutCmd Exception:", e
            }
            if(cmdTypes?.appCmds != null && cmdTypes?.appCmds?.size()) {
                cmdTypes?.appCmds?.each { appCmd->
                    noResp = true
                    ttsRespMap["appCmd"] = processAppCmd(appCmd, testMode, rData?.setValues)
                    showRespMap["appCommand"] = [type: "app command", desc: appCmd]
                    actionsTaken << "app command"
                }
            }
            try {
                if(cmdTypes?.modeCmd != null && cmdTypes?.modeCmd?.size()) {
                    def actStr = cmdTypes?.modeCmd[0]?.toString().split(":")
                    def act = actStr[0] ? actStr[0].toString() : (!cmdTypes?.modeCmd[0].contains(":") ? cmdTypes?.modeCmd[0] as String : null)
                    def actDelaySec = actStr[1] != null ? actStr[1]?.toInteger() : 0
                    def md = getStModeById(act)
                    if(md?.name) {
                        if(actDelaySec > 0) {
                            if(!testMode) {
                                if(canSchedule()) {
                                    runIn(actDelaySec, "procModeSched", [data:[act:md?.name, delay:actDelaySec], overwrite: false])
                                    ttsRespMap["mode"] = "I will set you're SmartThings mode to ${md?.name} in ${secondsTimeDesc(actDelaySec)}. "
                                    showRespMap["mode"] = [type: "mode", desc: "Setting SmartThings Mode to ${md?.name} in ${secondsTimeDesc(actDelaySec)}"]
                                } else {
                                    ttsRespMap["mode"] = "I really want to schedule this mode change to ${md?.name} but there aren't any available schedule slots available. Please try again in a few seconds."
                                }
                            }
                        } else {
                            if(!testMode) { setLocationMode(md?.name) }
                            ttsRespMap["mode"] = "I've set you're SmartThings mode to ${md?.name}"
                            showRespMap["mode"] = [type: "mode", desc: "SmartThings Mode Set to ${md?.name}"]
                        }
                        schedDbUpdate=true
                        actionsTaken << "location mode"
                    }
                }
            } catch (e) {
                wasError=true
                log.error "procLambdaCmds modeCmd Exception:", e
                ttsErrorResp = getRandomErrorPrefix() + "There was an error while trying to set your SmartThings mode."
            }
            try {
                if(cmdTypes?.routineCmd != null && cmdTypes?.routineCmd?.size()) {
                    def actStr = cmdTypes?.routineCmd[0]?.toString().split(":")
                    def act = actStr[0] ? actStr[0].toString() : (!cmdTypes?.routineCmd[0].contains(":") ? cmdTypes?.routineCmd[0] : null)
                    def actDelaySec = actStr[1] != null ? actStr[1]?.toInteger() : 15
                    def rtn = getRoutineById(act)
                    if(rtn?.label) {
                        if(actDelaySec > 0) {
                            if(!testMode) { runIn(actDelaySec, "procRoutineSched", [data:[act:rtn?.label, delay:actDelaySec], overwrite: false]) }
                            ttsRespMap["routine"] = "I will execute the ${rtn?.label?.toString()?.replaceAll("[^a-zA-Z0-9]", "")} routine in ${secondsTimeDesc(actDelaySec)}. "
                            showRespMap["routine"] = [type: "routine", desc: "Executing ${rtn?.label?.toString()?.replaceAll("[^a-zA-Z0-9]", "")} in ${secondsTimeDesc(actDelaySec)}"]
                        } else {
                            if(!testMode) {
                                if(canSchedule()) {
                                    location.helloHome?.execute(rtn?.label)
                                    ttsRespMap["routine"] = "I've executed the ${rtn?.label?.toString()?.replaceAll("[^a-zA-Z0-9]", "")} routine"
                                    showRespMap["routine"] = [type: "routine", desc: "Executed ${rtn?.label?.toString()?.replaceAll("[^a-zA-Z0-9]", "")}"]
                                } else {
                                    ttsRespMap["mode"] = "I really want to schedule the ${rtn?.label} routine to run but there aren't any available schedule slots available. Please try again in a few seconds."
                                }
                            }
                        }
                        schedDbUpdate=true
                        actionsTaken << "routine"
                    }
                }
            } catch (e) {
                wasError=true
                log.error "procLambdaCmds routineCmd Exception:", e
                ttsErrorResp = getRandomErrorPrefix() + "There was an error while trying to execute your routine."
            }
            try {
                if(cmdTypes?.shmCmd != null && cmdTypes?.shmCmd?.size()) {
                    def actStr = cmdTypes?.shmCmd[0]?.toString().split(":")
                    def act = actStr[0] ? actStr[0].toString() : (!cmdTypes?.shmCmd[0].contains(":") ? cmdTypes?.shmCmd[0] as String : null)
                    def actDelaySec = actStr[1] != null ? actStr[1]?.toInteger() : 0
                    if(actDelaySec>0) {
                        if(!testMode) {
                            if(canSchedule()) {
                                runIn(actDelaySec, "procAlarmSched", [data:[act:act, delay:actDelaySec], overwrite: false])
                                ttsRespMap["alarm"] = "${act == "disarm" ? "I will disarm the alarm" : "I will set the alarm mode to ${act}"} in ${secondsTimeDesc(actDelaySec)}."
                                showRespMap["alarm"] = [type: "alarm", desc: "${act == "disarm" ? "Disarming the Alarm" : "Setting Alarm to ${act}"} in ${secondsTimeDesc(actDelaySec)}"]
                            } else {
                                ttsRespMap["mode"] = "I really want to set the alarm to ${act} but there aren't any available schedule slots available. Please try again in a few seconds."
                            }
                        }
                    } else {
                        if(!testMode) { sendLocationEvent(name: 'alarmSystemStatus', value: act) }
                        ttsRespMap["alarm"] = "${act == "disarm" ? "Disarmed the Alarm" : "I've set the alarm mode to ${act}"}"
                        showRespMap["alarm"] = [type: "alarm", desc: "${act == "disarm" ? "Disarmed the Alarm" : "Set Alarm Mode to ${act}"}"]
                    }
                    schedDbUpdate=true
                    actionsTaken << "shmaction"
                }
            } catch (e) {
                wasError=true
                log.error "procLambdaCmds shmCmd Exception:", e
                ttsErrorResp = getRandomErrorPrefix() + "There was an error while trying to set the alarm state."
            }
        }
	} catch (ex) {
        wasError = true
		log.error "procLambdaCmds Exception:", ex
        status["data"] = "${ex}"
        status["code"] = 500
        ttsErrorResp = getRandomErrorPrefix() + getRandomItem(["SmartThings encountered an error while trying to complete the request.  Please try again later.", "SmartThings is having issues again ${getTimeOfDayDesc(true)}!.  Please try again in a moment."])
	}

    status["code"] = 200
    status["data"] = []
    status["sessionId"] = rData?.sessionId
    status["requestId"] = rData?.requestId
    //This handles the voice feedback strings
    def ttsResp = (!wasError && feedbackType in ["default", "short"]) ? getRandomOkPrefix() : ""
    if (!appMaint) {
        if(wasError) {
            ttsRespMap?.size() ? (ttsResp += "${ttsErrorResp},") : (ttsResp = ttsErrorResp)
        } else if (!ttsRespMap?.size() && feedbackType != "none") {
            ttsResp = feedbackType == "default" ? getRandomErrorPrefix() + "I wasn't able to take any actions with the request i was given. " : "Something went wrong. "
        } else {
            if(!(feedbackType in ["none", "short"])) {
                if (ttsRespMap?.allSkipped != null && ttsRespMap?.size() <2) {
                    ttsResp = ttsRespMap?.allSkipped
                } else {
                    def tcnt = 1
                    ttsRespMap?.each { rdrm->
                        ttsResp += "${tcnt>1 ? "and" : ""} ${rdrm?.value}"
                        tcnt=tcnt+1
                    }
                }
            }
        }
    } else { ttsResp = getRandomErrorPrefix() + "The App and Profiles are currently under going a rebuild!!! Please wait 15 seconds and try your request again." }
    if(noResp) { ttsResp = '' }
	//if(quietMode == true && feedbackType != "none") { ttsResp = "<amazon:effect name='whispered'>${ttsResp}</amazon:effect>" }
    // log.debug "ttsResp: ${ttsResp}"
    logOut << "\n│───────────────Other Info───────────────"
    logOut << "\n│    Quiet Mode([DB: ${rData?.setValues?.quietMode}, ST: ${settings["quietMode"]}]"
    logOut << "\n│     Test Mode: [${rData?.setValues?.testMode}]"
    logOut << "\n│ Feedback Type: [${rData?.setValues?.feedbackType}]"
    logOut << "\n│      WasError: (${wasError})"
    logOut << "\n│   Voice Reply: ${cleanSsml(ttsResp)}"
    logOut << "\n│       Actions: [${actionsTaken?.unique()}]"
    logOut << "\n│  Process Time: (${((now()-exTime)/1000).toDouble().round(2)}sec)"
    logOut << "\n└─────────────────────────────────────────"
    LogAction(logOut, "trace", true)
    if(schedDbUpdate) { schedLambdaStatusUpd(5, " | (Command Action)", true) }
    return [
        contentType: 'application/json', data: status?.data, ttsResp: ttsResp, showResp: showRespMap, appMaint: appMaint,
        wasError: wasError, quietMode: quietMode, followupMode: allowFollowupMode(), status: status?.code
    ]
}

void awsCmdLogs() {
    def logs = atomicState?.awsCmdLogs
    if(logs) {
        LogAction(logs, "trace", true)
        atomicState?.awsCmdLogs = null
    }
}

void procRoutineSched(data) {
    LogAction("procAlarmSched", "trace", true)
    if(data && data?.act) {
        location.helloHome?.execute(obj?.act)
        LogAction("Ran (${data?.act}) Routine after a ${data?.delay} seconds as requested.", "debug", true)
    }
}

void procModeSched(data) {
    LogAction("procAlarmSched", "trace", true)
    if(data && data?.act) {
        setLocationMode(data?.act)
        LogAction("Set Location to (${data?.act}) after a ${data?.delay} seconds as requested.", "debug", true)
    }
}

void procAlarmSched(data) {
    LogAction("procAlarmSched", "trace", true)
    if(data && data?.act) {
        sendLocationEvent(name: 'alarmSystemStatus', value: data?.act)
        LogAction("Set Alarm to (${data?.act}) after a ${data?.delay} seconds as requested.", "debug", true)
    }
}

void processSettings() {
    log.trace "processSettings"// | queue: ${atomicState?.settingUpdateQueue}"
    def sData = atomicState?.settingUpdateQueue ?: []
    if(sData?.size()) {
        sData?.each { set->
            def setobj = settings[set?.key.toString()]
            def type = getObjType(set?.value) ?: ""
            log.debug "settings[${set?.key}]: (${setobj}) | New: (${set?.value}) | type: ($type)"
            if(setobj != null) {
                if(setobj.toString() != set?.value.toString()) { settingUpdate(set?.key.toString(), set?.value.toString()) }
            } else { if(type == "Boolean") { settingUpdate(set?.key.toString(), set?.value.toString(), type?.toString()) } }
        }
        schedLambdaStatusUpd(5, " | (Settings Updated)", true)
        atomicState?.settingUpdateQueue = null
    }
}

def processAppCmd(cData, testMode=false, extData=null) {
    def resp = ""
    def cmdData = []
    if(cData instanceof String) { cmdData << cData }
    else { cmdData = cData }
    if(cmdData?.size()) {
        cmdData?.each { cmd->
            switch(cmd) {
                case "settingUpdate":
                    if(extData) {
                        atomicState?.settingUpdateQueue = extData ?: null
                        runIn(4, "processSettings", [overwrite: true])
                        resp += " ."
                    }
                break
                default:
                    resp = "Sorry but i was unable to process any commands. "
                break
            }
        }
    }
    return resp
}

def processShortcutCmd(cmdData, skipDevs=[], testMode=false, delay=0) {
    //log.trace "processShortcutCmd($cmdData)"
    def reply = [:]
    def resp = "I did not receive valid commands to handle shortcut actions.  Please try again later. "
    reply["error"] = true
    def cmds = []
    cmds = (cmdData instanceof String) ? cmds << cmdData : cmdData
    if(cmds?.size()) {
        def cnt = 0
        resp = ""
        cmds?.each { cmd->
            if(cmd) {
                def str = cmd?.toString()?.split(":")
                if(str[0] && str[1]) {
                    def prof = getProfileApps().find { it?.id?.toString() == str[0] as String }
                    if(prof) {
                        def r = prof?.runShortcutAction(str[1], skipDevs, testMode, delay)
                        if(r) {
                            reply["error"] = false
                            resp += r?.resp?.toString() + (cnt>1 ? ", and" : "")
                            cnt=cnt+1
                        }
                    }
                }
            } else {resp = "I was unable to parse out the profile for the desired shortcut action.  Please try again later. "}
        }
    }
    reply["resp"] = resp
    return reply
}
