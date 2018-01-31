/*
 *  Profile/Room - EchoSistant5 Add-on
 *
 *  Based off the idea of V1-V4 Written by Jason Headley & Bobby Dobrescu
 *  Copyright 2018 EchoSistant Team (Anthony Santilli, Corey Lista, Jason Headley, Bobby Dobrescu)
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License. You may obtain a copy of the License at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
 *  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
 *  for the specific language governing permissions and limitations under the License.
 *
/**********************************************************************************************************************************************/
import groovy.json.JsonSlurper
import java.text.SimpleDateFormat

definition(
	name			: "ES-Profiles",
    namespace		: "Echo",
    author			: "JH/BD",
	description		: "EchoSistant5 Profiles Add-on\n\nDO NOT install from the Marketplace",
	category		: "My Apps",
    parent			: "Echo:EchoSistant5",
	iconUrl			: "https://echosistant.com/es5_content/images/es5_rooms.png",
	iconX2Url		: "https://echosistant.com/es5_content/images/es5_rooms.png",
	iconX3Url		: "https://echosistant.com/es5_content/images/es5_rooms.png")
/**********************************************************************************************************************************************/
private releaseVer() { return "5.0.0117" }
private appVerDate() { "1-17-2018" }
private moduleType() { return "profile" }
/**********************************************************************************************************************************************/
preferences {
	page name: "startPage"
	page name: "notAllowedPage"
    page name: "mainProfilePage"
    //"Devices, Groups, Feedback, and Keypads"//
    page name: "devices"
    page name: "pDevices"
    page name: "pGroups"
    page name: "pGroup"
    page name: "pKeypads"
    page name: "pPerson"

	page name: "pShortcuts"

    //"Message Output and Alexa Responses"//
    page name: "messaging"
    //SETTINGS//
    page name: "pRestrict"
    page name: "certainTime"
    page name: "pSecurity"
    page name: "pActions"
    page name: "pDeviceControl"
    page name: "pWeatherConfig"
    page name: "pSkillConfig"
}
//////////////////////////////////////////////////////////////////////////////
/////////// MAIN PAGE
//////////////////////////////////////////////////////////////////////////////

//This Page is used to load either parent or child app interface code
def startPage() {
	if(parent) {
		if(!atomicState?.isInstalled && parent?.state?.ok2InstallProfFlag != true) {
			notAllowedPage()
		} else {
			atomicState?.isParent = false
			mainProfilePage()
		}
	}
}

def notAllowedPage () {
	dynamicPage(name: "notAllowedPage", title: "This install Method is Not Allowed", install: false, uninstall: true) {
		section() {
			paragraph "HOUSTON WE HAVE A PROBLEM!\n\nES Profiles can't be directly installed from the Marketplace.\n\nPlease use the ${parent?.name} SmartApp to configure them.", required: true,
			state: null, image: getAppImg("disable2.png")
		}
	}
}

def mainProfilePage() {
    dynamicPage(name: "mainProfilePage", title:"", install: true, uninstall: atomicState?.isInstalled) {
		appInfoSect()
        section ("Profile Invocation:") {
			input "roomName", "text", title: "Profile Invocation Name", description: "This will be used to target devices in this profile", image: getAppImg("es5_int_name.png")
		}
        section("Device Management") {
			def devCnt = settings?.allDevices?.size() ?: 0
			def devDesc = devCnt ? "Devices: ($devCnt)\n\nTap to Configure" : "Tap to Configue"
            href "devices", title: "Manage Devices", description: devDesc, state: (devCnt>0 ? "complete" : ""), image: getAppImg("devices.png")
        }
        section("Manage Shortcuts") {
			def shrtCutCnt = getShortcutApps()?.size() ?: 0
			def shrtCutDesc = (shrtCutCnt > 0) ? "Shortcuts: ($shrtCutCnt)\n\nTap to Configure" : "Tap to Configure"
            href "pShortcuts", title: "Create Shortcuts Actions", description: shrtCutDesc, required: false, state: (shrtCutCnt>0 ? "complete" : ""), image: getAppImg("es5_shortcuts.png")
        }
        section("Override Global Profile Settings") {
			paragraph title: "What does this do?", "This overrides the main apps global and will basically restrict any outside changes.\nThis will require you to manually manage every about the profile"
			input "profLockFromParentChanges", "bool", title: "Lock Profile from Automated Changes", required: false, defaultValue: false, submitOnChange: true, image: getAppImg("lock.png")
		}
		section("Profile Settings" , hideable: true, hidden: atomicState?.isInstalled) {
			href "pDefaults", title: "Profile Defaults", image: getAppImg("default.png")
            //href "pActions", title: "Profile Actions (to execute when Profile runs)"
			label title:"Profile Name", required:true, defaultValue: "ES-Profile", image: getAppImg("es5_prf_name.png")
        }
		atomicState.ok2InstallShortcutFlag = true
	}
}

def appInfoSect() {
    section("Echosistant Profile Info:") {
        def str = "Profile Version: V${releaseVer()}"
		str += "\nModified: ${appVerDate()}"
        str += "\nState Usage: ${getStateSizePerc()}%"
		str += "\n\nDeviceMap Updated:\n(${atomicState?.lastDeviceMapBuild ? prettyDt(atomicState?.lastDeviceMapBuild) : "Never"})"
        paragraph str, state: "complete", image: getAppImg("es5_rooms.png")
    }
}

//////////////////////////////////////////////////////////////////////////////
/////////// INDIVIDUAL DEVICE CONTROL
//////////////////////////////////////////////////////////////////////////////
def devices(){
    dynamicPage(name: "devices", title: "", uninstall: false){
		// section("Most Devices") {
			// def req = (settings["dev:sensors"] || settings["dev:actuator"])
			// input "dev:actuator", "capability.actuator", multiple: true, title: "Which actuators", required: req, submitOnChange: true
			// input "dev:sensor", "capability.sensor", multiple: true, title: "Which sensors", required: req, submitOnChange: true
			//input "allDevices", "capability.actuator", multiple: true, title: "Which actuators", required: req, submitOnChange: true
		// }
		// section("Device Select") {
            // paragraph "Nothing Here Yet"
			// input(type: "enum", name: "deviceSelector", title: "Use these devices", description: "This contains all available devices", groupedOptions: getMasterDeviceEnum(), multiple: true, required: false)
			// input "dev:test", "capability.actuator", title: "Allow These...", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("lock.png")
		// }
		section("Lights, Switches, Dimmers") {
            input "dev:light", "capability.light", title: "Select Lights/Bulbs..", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("light.png")
            input "dev:switch", "capability.switch", title: "Select Switches...", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("switch.png")
            input "dev:switchLevel", "capability.switchLevel", title: "Select devices that can take a level..", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("speed_knob.png")
        }
		section("Fans") {
            input "dev:fan", "capability.switch", title: "Select Fan Devices..", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("fan.png")
        }
        section("Locks") {
            input "dev:lock", "capability.lock", title: "Allow These Lock(s)...", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("lock.png")
        }
        section("Garage/Doors") {
            input "dev:garageDoorControl", "capability.garageDoorControl", title: "Select garage doors", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("garage_door.png")
        	input "dev:doorControl", "capability.doorControl", title: "Select doors", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("door_control.png")
            //input "dev:relay", "capability.switch", title: "Select Garage Door Relay(s)...", multiple: false, required: false//, submitOnChange: true
			//if (settings["dev:relay"]) {
            //	input "dev:contactRelay", "capability.contactSensor", title: "Allow This Contact Sensor to Monitor the Garage Door Relay(s)...", multiple: false, required: false
        	//}
        }
        section("Window Coverings", hideWhenEmpty: true) {
            input "dev:windowShade", "capability.windowShade", title: "Select devices that control your Window Coverings", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("window_shade.png")
        }
        section("Climate Control") {
            input "dev:thermostat", "capability.thermostat", title: "Allow These Thermostat(s)...", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("thermostat.png")
            input "dev:temperatureMeasurement", "capability.temperatureMeasurement", title: "Allow These Device(s) to Report the Indoor Temperature...", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("temp.png")
            //input "dev:outdoor", "capability.temperatureMeasurement", title: "Allow These Device(s) to Report the Outdoor Temperature...", multiple: true, hideWhenEmpty: true, required: false
            input "dev:vent", "capability.vent", title: "Select Smart Vents", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("vent.png")
        }
		section("Water", hideWhenEmpty: true) {
			input "dev:valve", "capability.valve", title: "Select Water Valves", required: false, multiple: true, hideWhenEmpty: true, submitOnChange: true, image: getAppImg("valve.png")
			input "dev:waterSensor", "capability.waterSensor", title: "Select Water Sensor(s)", required: false, multiple: true, hideWhenEmpty: true, submitOnChange: true, image: getAppImg("water.png")
		}
		section("Media", hideWhenEmpty: true) {
			input "dev:musicPlayer", "capability.musicPlayer", title: "Allow These Media Player Type Device(s)...", required: false, multiple: true, hideWhenEmpty: true, submitOnChange: true, image: getAppImg("media_player.png")
	     	input "dev:speechSynthesis", "capability.speechSynthesis", title: "Allow These Speech Synthesis Capable Device(s)", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("speech.png")
			input "dev:mediaController", "capability.mediaController", title: "Allow These Media Controller(s)", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("media_player.png")
    	}

        section("Feedback Only Devices", hideWhenEmpty: true) {
			input "dev:motionSensor", "capability.motionSensor", title: "Select Motion Sensors...", required: false, multiple: true, hideWhenEmpty: true, submitOnChange: true, image: getAppImg("motion.png")
            input "dev:contactSensor", "capability.contactSensor", title: "Select contacts connected to Doors and Windows", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("contact.png")
            input "dev:presenceSensor", "capability.presenceSensor", title: "Select These Presence Sensors...", required: false, multiple: true, hideWhenEmpty: true, submitOnChange: true, image: getAppImg("recipient.png")
            input "dev:battery", "capability.battery", title: "Select These Device(s) with Batteries...", required: false, multiple: true, hideWhenEmpty: true, submitOnChange: true, image: getAppImg("battery2.png")
			input "dev:carbonDioxideMeasurement", "capability.carbonDioxideMeasurement", title: "Select Carbon Dioxide Sensors (CO2)", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("co2_warn_status.png")
			input "dev:carbonMonoxideDetector", "capability.carbonMonoxideDetector", title: "Select Carbon Monoxide Sensors (CO)", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("co2_warn_status.png")
			input "dev:relativeHumidityMeasurement", "capability.relativeHumidityMeasurement", title: "Select Relative Humidity Sensor(s)", multiple: true, hideWhenEmpty: true, required: false, submitOnChange: true, image: getAppImg("humidity.png")
			input "dev:soundPressureLevel", "capability.soundPressureLevel", title: "Select Sound Pressure Sensor(s) (noise level)", multiple: true, hideWhenEmpty: true, submitOnChange: true, required: false
        }
		section("Don't Use These Devices In Group Commands:") {
			paragraph title: "What does this do?", "This will require you to use the word 'All' in your command to control these devices in group commands.\nSo if you say turn off the lights it will exclude these devices unless you add all to the command."
			input name: "hideFromGroupCmds", type: "enum", title: "Don't Use These with Groups", multiple: true, submitOnChange: true, required: false, metadata: [values:buildDeviceListEnum()], image: getAppImg("ignore.png")
		}
		section("Exclude These Devices From USE:") {
			paragraph title: "What does this do?", "Selecting a device here will remove it from all inputs.\nThis won't occur until a few seconds after you press done to return to the parent app."
			input name: "excludedDevs", type: "enum", title: "Don't Use These Devices", multiple: true, submitOnChange: true, required: false, metadata: [values:buildDeviceListEnum()], image: getAppImg("exclude.png")
		}
		devChgFlag(true)
	}
}

//////////////////////////////////////////////////////////////////////////////
/////////// SHORTCUTS
//////////////////////////////////////////////////////////////////////////////
def pShortcuts() {
    dynamicPage (name: "pShortcuts", title: "", install: false, uninstall: false) {
        section("Shortcuts"){
			if (!childApps?.size()) { paragraph "NOTE: It Looks like you haven't created any Shortcut's yet!\nTap on Create a New Shortcut to get started.", required: true, state: null }
        	app(name: "shortcut", appName: "ES-Shortcuts", namespace: "Echo", title: "Create a new Shortcut", multiple: true,  uninstall: false, image: getAppImg("es5_shortcuts.png"))
        }
	}
}

//////////////////////////////////////////////////////////////////////////////
/////////// PROFILE DEFAULTS
//////////////////////////////////////////////////////////////////////////////
def pDefaults(){
    dynamicPage(name: "pDefaults", title: "", uninstall: false){
		section("NOTICE:") {
			paragraph "These settings are not currently being used."
		}
        section ("General Control") {
            input "cLevel", "number", title: "Alexa Adjusts Light Levels by using a scale of 1-10 (default is +/-3)", defaultValue: 3, required: false
            input "cVolLevel", "number", title: "Alexa Adjusts the Volume Level by using a scale of 1-10 (default is +/-2)", defaultValue: 2, required: false
            input "cTemperature", "number", title: "Alexa Automatically Adjusts temperature by using a scale of 1-10 (default is +/-1)", defaultValue: 1, required: false
        }
        section ("Fan Control") {
            input "cHigh", "number", title: "Alexa Adjusts High Level to 99% by default", defaultValue: 99, required: false
            input "cMedium", "number", title: "Alexa Adjusts Medium Level to 66% by default", defaultValue: 66, required: false
            input "cLow", "number", title: "Alexa Adjusts Low Level to 33% by default", defaultValue: 33, required: false
            input "cFanLevel", "number", title: "Alexa Automatically Adjusts Ceiling Fans by using a scale of 1-100 (default is +/-33%)", defaultValue: 33, required: false
        }
        section ("Activity Defaults") {
            input "cLowBattery", "number", title: "Alexa Provides Low Battery Feedback when the Bettery Level falls below... (default is 25%)", defaultValue: 25, required: false
            input "cInactiveDev", "number", title: "Alexa Provides Inactive Device Feedback when No Activity was detected for... (default is 24 hours) ", defaultValue: 24, required: false
        }
        section ("Alexa Voice Settings") {
            input "pDisableContCmds", "bool", title: "Disable Conversation (Alexa no longer prompts for additional commands except for 'try again' if an error ocurs)?", required: false, defaultValue: false
            input "pEnableMuteAlexa", "bool", title: "Disable Feedback (Silence Alexa - it no longer provides any responses)?", required: false, defaultValue: false
            input "pUseShort", "bool", title: "Use Short Alexa Answers (Alexa provides quick answers)?", required: false, defaultValue: false
        }
    }
}

def getDefaultsMap(capabs) {
	if(!capabs) { return null }
	def list = [:]
	if(capabs?.contains("Light")) {
		list["volume"] = [:]
		list?.light["level"] = settings?.cVolLevel ?: 3
	}
	if(capabs?.contains("Light")) {
		list["light"] = [:]
		list?.light["level"] = settings?.cLevel ?: 3
	}
	if(capabs?.contains("Temperature")) {
		list["temperature"] = [:]
		list?.temperature["level"] = settings?.cTemperature ?: 1
	}
	return list
}

def getAutomationType() {return settings?.childTypeFlag?.toString() ?: null}
def getRoomId() {return settings["roomId"] as String ?: null}
def getRoomName(clnName=false) {return clnName ? settings["clnRoomName"].toString() : settings["roomName"].toString()}

/************************************************************************************************************
		Base Process
************************************************************************************************************/

def devChgFlag(val=true) { atomicState?.deviceChgsPending = val }
def sendFullDevMapFlag(val=true) { atomicState?.sendFullDevMap = val }

def installed() {
    //log.debug "Installed with settings: ${settings}, current app version: ${releaseVer()}"
	atomicState?.isInstalled = true
	initialize()
}

def updated() {
    //log.debug "Updated with settings: ${settings}, current app version: ${releaseVer()}"
    atomicState?.appUpdInProg = true
	atomicState?.appUpdStartDt = getDtNow()
    if(parent?.getProfileDevUpdSettings()?.nameOverride == true) {
        def rmName = parent?.getStRoomNameById(getRoomId())
        if(rmName != null) {
			def clnName = capitalizeAll(cleanString(rmName)).replaceAll(" ", "")
            if(settings?.roomName?.toString() != rmName.toString()) { settingUpdate("roomName", rmName?.toString(), "text") }
            if(settings?.clnRoomName?.toString() != clnName ) { settingUpdate("clnRoomName", clnName?.toString(), "text") }
			atomicState?.fullRoomName = rmName.toString()
            atomicState?.clnRoomName = rmName.toString().replaceAll(" ", "")
            def label = "ES-Room | ${rmName}"
            if(app?.label.toString() != label) { app?.updateLabel(label) }
        }
    }
    // LogAction("Updated Profile: (${app?.label})", "trace", true)
    initialize()
}

def cleanString(str) {
	return str.replaceAll(/[^a-zA-Z0-9 ]/, "").replace(/\s{2,}/, " ").trim()
}

def capitalizeAll(str) {
	return str?.split(" ").collect{it?.capitalize()}?.join(" ")
}

def getUpdStartDtSec() { return !atomicState?.appUpdStartDt ? 7200 : GetTimeDiffSeconds(atomicState?.appUpdStartDt, null, "getUpdStartDtSec").toInteger() }

def initialize() {
    log.debug "Initialized (${app.label}) | Profile Version: (${releaseVer()})"
	if(atomicState?.roomId == null) { atomicState?.roomId = settings?.roomId?.toString() }
	devChgFlag(true)
	if(atomicState?.deviceChgsPending==true) {
		unsubscribe()
		def maintWait = 4
		runIn(maintWait, "profileMaint", [overwrite: true])
		LogAction("Profile Maintenance Scheduled to Start in (${maintWait}sec)...", "info", true)
	}
	stateCleanup()
	sendFullDevMapFlag(true)
}

def uninstalled() {
	LogAction("Removed Profile: (${app?.getLabel()}) Successfully...", "warn", true)
}

def getShortcutId(){return atomicState?.shortcutAppId ?: null}
def getShortcutVer(){return atomicState?.shortcutVer ?: null}

void updShortcutAppId(id) { atomicState?.shortcutAppId = id }
void updShortcutVer(ver) {
    if(ver != null) {
        log.debug "Shortcut Version Updated to: ${ver}"
        atomicState?.shortcutVer = ver
    }
}

def getShortcutNames() {
	// def items = getChildApps()?.findAll { ca?.getSettings()?.showInWebCore != null && ca?.getSettings()?.showInWebCore == true }.collect { it?.getShortcutName() }
	return atomicState?.webCoreShortcuts ?: []
}

def profileMaint() {
	updDeviceInputs()
	runIn(3, "updChildren", [overwrite: true])
    //runIn(13, "postMaintTasks"), [overwrite: true])
	subscriber()
	LogAction("Profile Maintenance Complete. Device Map Update will Start in (5sec)...", "info", true)
	
	schedDevStateUpd()
}

void updChildren() {
    def shId = null
    def shVer = null
	def wcShrtcuts = []
    getChildApps()?.each {
        if(shId == null) {shId = it?.smartAppId}
        if(shVer == null) {shVer = it?.releaseVer()}
		if(it?.getShowInWebCore()) { wcShrtcuts.push(it?.getShortcutName()) }
        it?.update()
    }
    atomicState?.shortcutAppId = shId
    atomicState.shortcutVer = shVer
	atomicState?.webCoreShortcuts = wcShrtcuts
    if(shId) { parent?.updShortcutAppId(shId) }
    if(shVer) { parent?.updVersionData("shrtCutVer", shVer) }
    // log.debug "shortcutAppId: ${atomicState?.shortcutAppId} | shortcutVer: ${atomicState?.shortcutVer}"
}

void postMaintTasks() {}

def stateCleanup() {
    log.trace "stateCleanup"
    def data = ["appUpdateInProgress","parentDeviceList"]
    data.each { item ->
		if(state[item]) { state.remove(item?.toString()) }
    }
}

def clearAllDevSetInputs() {
	def devSets = getSettings()?.findAll { it?.key?.startsWith("dev:") }
	devSets?.each { ds->
		settingUpdate("${ds?.key}", [])
	}
}

def runShortcutAction(shrtCutId, skipDevs=[], testMode=false, delay=0) {
	def reply = [:]
	reply["error"] = true
	try {
		reply["error"] = true
		reply["resp"] = "I'm sorry but I couldn't find a profile with the shortcut you requested. "
		def scApp = getShortcutApps()?.find {it?.id?.toString() == shrtCutId.toString()}
	    if (scApp) {
			def res = scApp?.processActions(skipDevs, testMode, delay)
			if(res?.result == true) {
				reply["error"] = false
				if (res?.resp != null) { reply["resp"] = "${res.resp}" }
	            else { reply["resp"] = "executed the ${scApp?.getShortcutName()} in the, ${getRoomName()}. "}
			} else { reply["resp"] = "oops... i seemed to have an issue running the requested shortcut. " }
	    }
		// log.debug "reply: $reply"
	} catch(ex) {
		log.error "runShortcutAction ex:", ex
		reply["resp"] = "oops... i seemed to have an issue running the requested shortcut. "
	}
	return reply
}

def getProfItemCnts() {
	def items = [:]
	items["devices"] = masterDeviceList(true)?.sort()?.unique()?.size() ?: 0
	items["shortcuts"] = getShortcutApps()?.size() ?: 0
	items["quickActions"] = getShortcutApps()?.size() ?: 0
    return items
}

def getDeviceInputs() {
	return getSettings()?.findAll { it?.key?.startsWith("dev:") }
}

def masterDeviceList(onlyIds=false) {
	def devs = []
	def devSets = getDeviceInputs()
	devSets?.each { ds->
		//log.debug "${ds} (${getObjType(ds?.value)})"
		def dlst = onlyIds ? ds?.value?.collect {it?.id} : ds
		devs = devs + dlst
	}
    return devs
}

def buildDeviceListEnum() {
	def newList = []
	def profDevs = parent?.getProfileDeviceList(settings["roomId"], true)
	def curDevs = masterDeviceList(true) ?: []
	if (profDevs != null && curDevs != null) {
		newList = (profDevs + curDevs)?.sort()?.unique()  // add if statement to prevent null pointer exception when manually creating a profile
		settingUpdate("tmpDevs", newList as List, "capability.actuator")
		def data = settings["tmpDevs"]?.sort { it?.displayName }.collect { ["${it?.id}":it?.displayName] }
		// settingUpdate("tmpDevs", [], "capability.actuator")
		return data
	}
}

private updDeviceInputs() {
	// log.trace "updDeviceInputs()"
	def updDevSets = parent?.getProfileDevUpdSettings()
	def profileLocked = settings?.profLockFromParentChanges == true
	def excludedDevs = settings["excludedDevs"] ?: []
	def newDevs = []
	def curDevs = []
	if(updDevSets?.sync && !profileLocked) {
		newDevs = parent?.getProfileDeviceList(settings["roomId"], true)
		newDevs = newDevs?.sort()?.unique()
		if(updDevSets?.newOnly) {
			curDevs = masterDeviceList(true) ?: []
			curDevs = curDevs?.sort().unique()
		}
		newDevs?.each { inpt -> curDevs?.push(inpt) }
		clearAllDevSetInputs()
	} else {
		curDevs = masterDeviceList(true) ?: []
		curDevs = curDevs?.sort().unique()
	}
	def newList = []
	curDevs?.each { dev ->
		if(!excludedDevs?.contains(dev) && !(dev in newList)) { newList?.push(dev) }
	}
    settingUpdate("allDevices", newList as List, "capability.actuator")
	def allDevs = settings["allDevices"]
	if(allDevs?.size()>0) {
		def ign = ["configuration", "refresh", "healthCheck", "indicator", "polling", "outlet", "audioNotification", "lockCodes", "speechSynthesis", "tone" ]
        def items = getDeviceCapabList(allDevs)
        items?.each { item ->
			def capab = convCapabNameToInputStr(item)
			if(ign?.contains(capab?.toString())) { return }
            def devs = allDevs?.findAll { it?.capabilities?.collect { it as String }.contains(item) }.collect {it?.id}
            settingUpdate("dev:${capab}", devs, "capability.${capab}")
        }
		updCustCapabSettings(allDevs)
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

def custDevCapabsEnum(not4Set=false) {
	if(!not4Set) {
		return ["fan":"switch", "vent":"switchLevel", "light":"light", "bulb":"light", "door":"door", "window":"window"]
	} else { return ["fan":"switch", "vent":"switchLevel", "light":"switch"] }
}

def updCustCapabSettings(allDevs) {
	def types = custDevCapabsEnum()
	if(allDevs?.size()>0) {
        types?.each { ty ->
			String compStr = ty?.key
            def devs = allDevs?.findAll { ( it?.label?.contains(compStr) || it?.label?.contains(compStr.capitalize()) ) }.collect { it?.id }
			if(devs) {
            	settingUpdate("dev:${ty?.key}", devs, "capability.${ty?.value}")
			}
        }
    }
}

def optionsGroup(List groups, String title) {
    def group = [values:[], order: groups.size()]
    group.title = title ?: ""
    groups << group
    return groups
}
def addValues(List groups, String key, String value) {
    def lastGroup = groups[-1]
    lastGroup["values"] << [key: key, value: value, order: lastGroup["values"]?.size()]
    return groups
}
def listToMap(List original) {
    original?.inject([:]) { result, v ->
        result[v] = v
        return result
    }
}
def addGroup(List groups, String title, values) {
    if (values instanceof List) {values = listToMap(values)}
    values?.inject(optionsGroup(groups, title)) { result, k, v -> return addValues(result, k, v) }
    return groups
}
def addGroup(values) {
    addGroup([], null, values)
}
def getMasterDeviceEnum() {
	def devOpts = []
	def allDevs = settings["allDevices"] //parent?.settings["allDevices"]
	getMasterCapList(allDevs)?.each { mCap->
		def capList = [:]
    	allDevs?.sort { it?.displayName }?.each { dev ->
			if(getDevCapabilities(dev)?.find { it?.toString() == mCap?.toString()}) {
				capList["${dev?.id}"] = dev?.displayName as String
			}
		}
		addGroup(devOpts, mCap, capList)
	}
	log.debug "devOpts: $devOpts"
	return devOpts
}

def getMasterCapList(devs) {
	def capList = []
    devs?.sort { it?.displayName }.each { dev ->
		getDevCapabilities(dev)?.each { capList << it }
		capList = capList?.sort().unique()
	}
	return capList
}

def getDevCapabilities(dev, addCap=null) {
	def capabs = []
	if(dev) {
		def devLbl = dev?.displayName as String
		def devLblLc = devLbl?.toLowerCase() as String
		def devLblTkn = devLbl?.tokenize().collect{it?.toLowerCase()}
		//Reads the normal caps from the device (Basically a Starting point)
		capabs = dev?.capabilities?.collect{it as String}.findAll{!(ignoreTheseCaps()?.contains(it))}
		//Uses the label to add special caps to the device
		def lblToCaps = ["fan":"switch", "vent":"switchLevel"]
		lblToCaps?.each { ltc ->
			if(devLblTkn?.contains(ltc?.key.toString())) { capabs << ltc?.key?.toString()?.capitalize() }
        }
		//This uses the device.name to help identify devices like harmory activities and hub
		def typeToCaps = ["Harmony Activity":"Harmony Activity", "Logitech Harmony Hub C2C":"Harmony Hub"]
		typeToCaps?.each { tc-> if(tc?.key.toString()?.contains(dev?.name as String)) { capabs << tc?.value as String }}
		//This adds the custom labels based on the devices label
		def addCaps = ["outlet","vent","camera","garage door","door","window","keypad","siren","speaker","remote","minimote","doorbell"]
		addCaps?.each { ac->
            if(devLblTkn?.contains(ac?.toString()) || devLblLc?.contains(ac?.toString())) {
                if(ac?.toString() == "vent" && !devLblTkn?.find { it == ac?.toString() }) { return }
                capabs.push("${ac?.toLowerCase().tokenize().collect{it?.capitalize()}.join(' ')}")
            }
        }
		if(capabs?.contains("Door") && devLblLc?.contains("lock")) { capabs?.removeAll(["Door"]) }
		//This adds the light cap to devices with light or lamp or bulb in the label and removes Fan and Outlet if they exist
		if(devLblTkn?.contains("lamp") || devLblTkn?.contains("light") || devLblTkn?.contains("lights") || devLblTkn?.contains("bulb")) {
			if(devLblTkn?.contains("lamp")) { capabs.push("Lamp") }
			capabs.removeAll(["Fan", "Outlet"])
			capabs.push("Light")
		} else {
			//label contains fan we remove light and outlet
			if(devLblTkn?.contains("fan") && !devLblTkn?.contains("outlet")) {
				if(!capabs?.contains("Fan")) { capabs?.push("Fan") }
				capabs?.removeAll(["Light", "Outlet"])
			}
			//label contains outlet we remove light and fan
			if(devLblTkn?.contains("outlet") && !devLblTkn?.contains("fan")) {
				if(!capabs?.contains("Outlet")) { capabs?.push("Outlet") }
				capabs?.removeAll(["Light", "Fan"])
			}
		}
		//This cleans out the switch cap from devices with the following caps
		def removeSwitchList = ["Light", "Outlet", "Fan", "Thermostat", "Camera", "Media Player", "Speaker", "Speech Synthesis"]
		removeSwitchList?.each { rs->
			if(capabs?.find { it?.toString() == rs?.toString()}) { capabs?.removeAll(["Switch"])}
		}
		// log.debug "$devLbl | ${capabs?.sort()?.unique()}"
    }
	return capabs
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

def deviceInProfile(devId) {
	def allDevs = settings["allDevices"].collect {it?.id}
    if(allDevs.contains(devId)) {
		return true
	}
	return false
}

def getDeviceMap(chgsOnly) {
	def dMap = []
	if(atomicState?.appUpdInProg == true) { return [] }
	if(chgsOnly == false || atomicState?.sendFullDevMap == true) {
		dMap = atomicState?.selectedDevMap
		sendFullDevMapFlag(true)
	}// else { dMap = atomicState?.chgdDevsMap }
	// log.debug "dMap: (${dMap?.size()})"
	// def logStr ="Parent is Requesting DeviceMap${(chgsOnly == true && atomicState?.sendFullDevMap) ? " (ChgsOnly)" : ""} | Using ${chgsOnly == true ? "ChangedDevs" : "Stored"} Map | Sending (${dMap?.size() ?: 0} Devices)"
	// "Parent is Requesting DeviceMap (ChgsOnly) | Using ChangedDevs Map | Sending (100) Devices"
	//LogAction(logStr, "info", true)
	atomicState?.chgdDevsMap = []
    return dMap ?: []
}

def getAllProfileNames() {
	return parent?.getAllProfileNames()
}

void logTest(){
	def logs = atomicState?.logTest ?: []
	logs.each {
		log.info "${it.toString()}"
	}
	atomicState?.logTest = null
}

def ignoreTheseCaps() {
	return ["Health Check","Refresh","Indicator","Polling","Configuration","Sensor","Actuator", "Bridge"]
}

def ignoreTheseCmds(caps=null) {
	def items = [
		"ping","refresh","configure","poll","enrollResponse","indicatorWhenOn","indicatorWhenOn","indicatorNever","whoMadeChanges","ecoDesc",
		"cltLiveStreamStart","log","updateCodes","deleteCode","setCodeLength","reloadAllCodes","nameSlot","setCode","requestCode",
		"alloff","huboff","indicatorWhenOff","setEntryDelay","sendInvalidKeycodeResponse","testCmd","setExitDelay","unlockWithTimeout",
		"offPhysical","onPhysical","offsetOn","offsetOff","unlockwtimeout","lightLevel","lightOn","lightOff","setFanSpeed",
        "humidityDown","safetyHumidityMaxUp","comfortDewpointMaxDown","safetyTempMaxDown","safetyTempMinUp","comfortDewpointMaxUp",
        "safetyTempMinDown","setSchedule:json_object","safetyTempMaxUp","lockedTempMinDown","lockedTempMaxUp","lockedTempMaxDown",
        "changeTempLock","safetyHumidityMaxDown","humidityUp","lockedTempMinUp","heatbtn","coolbtn","offbtn","autobtn", "tileSetLevel",
		"unsubscribe", "subscribe", "playText", "setLocalLevel", "runSmokeTest", "runCoTest", "runBatteryTest", "test"
	]
	if(caps && !caps?.contains("Lock")) { items = items+["lock","unlock"] }
	return items
}

def updateDeviceMap() {
	//log.trace "updateDeviceMap()"
	def exTime = now()
	def devs = []
	def removeSwitch4These = ["Light", "Outlet", "Thermostat", "Camera", "Media Player", "Speech Synthesis"]
    def parVer = parent?.releaseVer()
    def parDt = parent?.appVerDate()
    def allDevs = settings["allDevices"]
    allDevs?.sort { it?.displayName }.each { dev ->
		if(!devs?.collect { it?.deviceId }?.contains(dev?.id)) {
			def v = [:]
			v["deviceId"] = dev?.id
			v["label"] = dev?.displayName
	        v["type"] = dev?.name
            // v["debug"] = [:]
            // v?.debug["profVer"] = releaseVer()
            v["dt"] = getDtNow()
			v["capabilities"] = getDevCapabilities(dev)?.sort()?.unique()
			def dCmds = dev?.supportedCommands?.findAll{!((it?.name as String) in ignoreTheseCmds(v?.capabilities))}?.collect{"${it?.name}${it?.arguments ? ":" + it?.arguments.toString()?.toLowerCase()?.replaceAll("\\[|\\]", "") : ""}"}?.sort()?.toSet() ?: []
			v["commands"] = devCmdTranslator(dCmds, v?.capabilities) ?: []
			//Adds in capabability for native NST Thermostat Reports
			if(v?.commands?.find { it.toLowerCase() == "updatenestreportdata"?.toLowerCase()}) { v["capabilities"]?.push("NestReport") }
			v["capabilities"]?.sort()
	        v["rooms"] = [getRoomName()]
			v["hideFromGroupCmds"] = (settings?.hideFromGroupCmds?.contains(dev?.id)) ? true : false

			//Add Current Device Attribute values to the map
            def tmp = [:]
            def items = sendTheseStates()
            items?.each { item-> if(dev?.hasAttribute(item)) {tmp["${item}"] = dev?.currentValue(item)}}
            v["states"]=tmp
			//Returns the device object to the device map
			devs << v
		}
    }

	//This will add the shortcuts into the deviceMap as a device
	def allProfNames = parent?.getAllProfileNames(false)
	// log.debug "allProfNames: $allProfNames"
	getShortcutApps()?.each { shrtCut->
		def lbl = shrtCut?.getShortcutName()?.toLowerCase()
		def gbl = (shrtCut?.getIsGlobalShortcut() == true)
		def v = [:]
		v["deviceId"] = shrtCut?.id
		v["label"] = lbl
		v["type"] = lbl
		// v["debug"] = [:]
		v["dt"] = getDtNow()
		v["capabilities"] = ["Shortcut"]
		v["commands"] = [lbl]
		v["rooms"] = gbl ? allProfNames : [getRoomName()]
		v["states"] = []
		devs << v
	}
	// log.debug "devs(${devs?.size()}): $devs"
    atomicState?.selectedDevMap = devs
    if(devs?.size() > 0) {
        atomicState?.lastDeviceMapBuild = getDtNow()
		devChgFlag(false)
		if(atomicState?.appUpdInProg) { LogAction("Device Map was Successfully Built in (${((now()-exTime)/1000).toDouble().round(2)}sec)", "info", true) }
        atomicState?.appUpdInProg = false
    }
    return devs
}

def devCmdTranslator(cmds, caps) {
	if(cmds == null) { return null }
	def lvlCmdMap = [
		"Level":["up", "more", "increase", "high", "down", "less", "decrease", "low"],
		"Light":["bright", "not bright enough", "too dark", "dark", "not dark enough", "too bright"],
		  "Fan":["fast", "quick", "slow", "high", "medium"],
		 "Vent":["open", "close"]
	]
	def newList = []
	cmds?.each { cmd->
		def cmdSplit = cmd?.toString()?.replaceAll(",", " ")?.split(":")
		def cmdStr = cmdSplit[0] ?: null
		def cmdParamSize = cmdSplit?.size() > 1 ? cmdSplit[1]?.split(" ")?.findAll {it != "" && it != null }?.size() : 0
		if(cmdStr) {
			if(cmdStr?.toLowerCase() == "setlevel") {
				newList?.push(cmdStr)
				lvlCmdMap?.each { cItem->
					if(caps?.contains(cItem?.key)) {
						cItem?.value?.each { newList?.push(it) }
					} else { lvlCmdMap["level"]?.each { newList?.push(it) } }
				}
			}
			if(cmdParamSize <= 1 ) { newList?.push(cmdStr) }
		}
	}
	// log.debug "newList: ${newList.unique()}"
	return newList?.unique()
}

def deviceStateUpdate(devId) {
	def data = atomicState?.selectedDevMap
	//def chgMap = atomicState?.chgdDevsMap ?: []
	if(data) {
		data?.each { dev->
			if(dev?.deviceId == devId) {
				if(dev?.states?.size()) {
					def tmp = [:]
					def items = sendTheseStates()
					def dv = getDevice(devId)
					if(dv) {
						items?.each { item->
							if(dv?.hasAttribute(item)) {
								tmp["${item}"] = dv?.currentValue(item)
							}
						}
					}
					dev["states"]=tmp
					dev["dt"] = getDtNow()
					atomicState?.selectedDevMap = data
					atomicState?.lastDevStateUpd = getDtNow()
				} else { schedDevStateUpd() }
				// chgMap << dev
				// log.debug "dev: $dev"
			}
		}
	} else { schedDevStateUpd() }
	//atomicState?.chgdDevsMap = chgMap
}

def getDevice(devId) {
	return settings["allDevices"]?.find { it?.id == devId } ?: null
}

void schedDevStateUpd() {
	sendFullDevMapFlag(true)
	runIn(3, "updateDeviceMap", [overwrite: true])
}

def getLastDevMapBuildDtSec() { return !atomicState?.lastDeviceMapBuild ? 7200 : GetTimeDiffSeconds(atomicState?.lastDeviceMapBuild, null, "getLastDevMapBuildDtSec").toInteger() }
def getLastDevStateUpdDtSec() { return !atomicState?.lastDevStateUpd ? 7200 : GetTimeDiffSeconds(atomicState?.lastDevStateUpd, null, "getLastDevStateUpdDtSec").toInteger() }

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

void subscriber() {
    log.trace "subscriber"
	def attrConv = [
		"switchLevel":"level","bulb":"switch","contactSensor":"contact","carbonDioxideMeasurement":"carbonDioxide","carbonMonoxideDetector":"carbonMonoxide",
		"colorControl":["color", "hue", "saturation"], "doorControl":"door", "energyMeter":"energy", "illuminanceMeasurement":"illuminance",
		"light":"switch", "mediaController":["activities", "currentActivity"], "motionSensor":"motion", "musicPlayer":["level", "mute", "status"],// "trackData", "trackDescription"],
		"powerMeter":"power", "presenceSensor":"presence", "relativeHumidityMeasurement":"humidity", "shockSensor":"shock", "sleepSensor":"sleeping",
		"smokeDetector":"smoke", "soundSensor":"sound", "speechRecognition":"phraseSpoken", "tamperAlert":"tamper", "thermostatCoolingSetpoint":"coolingSetpoint",
		"thermostatHeatingSetpoint":"heatingSetpoint", "temperatureMeasurement":"temperature", "voltageMeasurement":"voltage", "waterSensor":"water"
	]
	def dontSubscribe = [
		'configuration', 'refresh', 'healthCheck', 'indicator', 'polling', 'sensor', 'actuator', 'audioNotification', 'lockCodes', 'speechSynthesis', 'status', 'tone', 'power', 'energy', 'bridge'
	]
    def excludedDevs = settings["excludedDevs"] ?: []
	getDeviceInputs()?.each { ds->
		def spl = ds?.key?.split(":")
		def k = spl[1]
		def items = ds?.value
		if(items && !(dontSubscribe?.contains(k))) {
            items = items?.findAll { !(it?.id in excludedDevs) }
			def aItem = attrConv?.find { it?.key.toString() == k?.toString() }
			if(aItem?.value) {
				if(aItem?.value instanceof List) {
					aItem?.value?.each { av-> subscribe(items, "${av}", devEvtHandler) }
				} else if(aItem?.value instanceof String) { subscribe(items, "${aItem?.value}", devEvtHandler) }
			} else { subscribe(items, "${spl[1]}", devEvtHandler) }
			// LogAction("Subsribed to Devices (${items}) - ${spl[1]} Events", "trace", true)
		}
	}
}

def sendTheseStates() {
	return [
		'lock', "switch", 'level', 'contact', 'battery', 'alarm', 'button', "carbonDioxide",
		"color", "hue", "saturation", "colorTemperature", "door", "energy", "illuminance",
		"activities", "currentActivity", "motion", "mute", "status",, "temperature",// "trackData", "trackDescription"
		"power", "powerSource", "presence", "humidity", "shock", "sleeping","smoke", "carbonMonoxide", "phraseSpoken",
		"tamper", "coolingSetpoint", "heatingSetpoint", "thermostatFanMode", "thermostatMode", "thermostatOperatingState",
		"valve", "voltage", "water","windowShade"
	]?.sort().unique()
}

void devEvtHandler(evt) {
	def exTime = now()
	LogAction("${evt?.name.toUpperCase()} Event | Device: ${evt?.displayName} | Value: (${evt?.value.toString().capitalize()}${evt.unit ? "${evt.unit}" : ""}) with a delay of (${((now()-evt.date.getTime())/1000).toDouble().round(2)}sec)", "trace", true)
	if(atomicState?.appUpdInProg != true) {
		deviceStateUpdate(evt?.deviceId)
		parent?.handleDevEvt(evt, app.label)
	}
}

def getShortcutApps() {
    List sApps = getChildApps()?.findAll{ it?.moduleType().toString() == "shortcuts" }
    if(sApps?.size()) {
        return sApps
    } else { return null }
}

def getSettingsData() {
    def sets = []
    sets << settings?.sort().collect { it }
    return sets
}

def getSettingVal(var) {
    return settings[var] ?: null
}

def getStateVal(var) {
    return state[var] ?: null
}

void settingUpdate(name, value, type=null) {
    // log.trace("settingUpdate($name, $value, $type)...")
    if(name && type) { app?.updateSetting("$name", [type: "$type", value: value]) }
    else if (name && type == null) { app?.updateSetting(name.toString(), value) }
}

def stateUpdate(sKey, sValue) {
    if(sKey && sValue) {
		// log.info "Updating State Value (${sKey}) with | ${sValue}"
        atomicState?."${sKey}" = sValue
        return true
    } else { return false }
}

/******************************************************************************************************
   PARENT STATUS CHECKS
******************************************************************************************************/
def checkState() {return state.pMuteAlexa}
def getStateSize()	{ return state?.toString().length() }
def getStateSizePerc()  { return (int) ((state?.toString().length() / 100000)*100).toDouble().round(0) }

/***********************************************************************************************************************
    RESTRICTIONS HANDLER
***********************************************************************************************************************/
private getAllOk() {
	modeOk && daysOk && timeOk
}

private getModeOk() {
    def result = !modes || modes?.contains(location.mode)
	if(parent.debug) log.debug "modeOk = $result"
    result
}

private getDayOk() {
    def result = true
    if (days) {
        def df = new java.text.SimpleDateFormat("EEEE")
        if (location.timeZone) {
            df.setTimeZone(location.timeZone)
        }
        else {
            df.setTimeZone(TimeZone.getTimeZone("America/New_York"))
        }
        def day = df.format(new Date())
        result = days.contains(day)
    }
    if(parent.debug) log.debug "daysOk = $result"
    result
}

private getTimeOk() {
	def result = true
	if ((starting && ending) ||
	(starting && endingX in ["Sunrise", "Sunset"]) ||
	(startingX in ["Sunrise", "Sunset"] && ending) ||
	(startingX in ["Sunrise", "Sunset"] && endingX in ["Sunrise", "Sunset"])) {
		def currTime = now()
		def start = null
		def stop = null
		def s = getSunriseAndSunset(zipCode: zipCode, sunriseOffset: startSunriseOffset, sunsetOffset: startSunsetOffset)
		if(startingX == "Sunrise") start = s.sunrise.time
		else if(startingX == "Sunset") start = s.sunset.time
		else if(starting) start = timeToday(starting,location.timeZone).time
		s = getSunriseAndSunset(zipCode: zipCode, sunriseOffset: endSunriseOffset, sunsetOffset: endSunsetOffset)
		if(endingX == "Sunrise") stop = s.sunrise.time
		else if(endingX == "Sunset") stop = s.sunset.time
		else if(ending) stop = timeToday(ending,location.timeZone).time
		result = start < stop ? currTime >= start && currTime <= stop : currTime <= stop || currTime >= start
		if (parent.debug) {log.trace "getTimeOk = $result."}
    }
    return result
}

private hhmm(time, fmt = "h:mm a") {
	def t = timeToday(time, location.timeZone)
	def f = new java.text.SimpleDateFormat(fmt)
	f.setTimeZone(location.timeZone ?: timeZone(time))
	f.format(t)
}

private offset(value) {
	def result = value ? ((value > 0 ? "+" : "") + value + " min") : ""
}

private timeIntervalLabel() {
	def result = ""
	if      (startingX == "Sunrise" && endingX == "Sunrise") result = "Sunrise" + offset(startSunriseOffset) + " to Sunrise" + offset(endSunriseOffset)
	else if (startingX == "Sunrise" && endingX == "Sunset") result = "Sunrise" + offset(startSunriseOffset) + " to Sunset" + offset(endSunsetOffset)
	else if (startingX == "Sunset" && endingX == "Sunrise") result = "Sunset" + offset(startSunsetOffset) + " to Sunrise" + offset(endSunriseOffset)
	else if (startingX == "Sunset" && endingX == "Sunset") result = "Sunset" + offset(startSunsetOffset) + " to Sunset" + offset(endSunsetOffset)
	else if (startingX == "Sunrise" && ending) result = "Sunrise" + offset(startSunriseOffset) + " to " + hhmm(ending, "h:mm a z")
	else if (startingX == "Sunset" && ending) result = "Sunset" + offset(startSunsetOffset) + " to " + hhmm(ending, "h:mm a z")
	else if (starting && endingX == "Sunrise") result = hhmm(starting) + " to Sunrise" + offset(endSunriseOffset)
	else if (starting && endingX == "Sunset") result = hhmm(starting) + " to Sunset" + offset(endSunsetOffset)
	else if (starting && ending) result = hhmm(starting) + " to " + hhmm(ending, "h:mm a z")
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

def prettyDt(dt) {
    if(!dt) { return null }
    def newDt = Date.parse("E MMM dd HH:mm:ss z yyyy", dt)
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

def splitCamelCase(String s, retStr=false) {
   def r = s.replaceAll(String.format("%s|%s|%s", "(?<=[A-Z])(?=[A-Z][a-z])", "(?<=[^A-Z])(?=[A-Z])", "(?<=[A-Za-z])(?=[^A-Za-z])"),"${retStr ? " " : ","}")
   if(retStr) { return r }
   else { return r?.split(",")}
}

def formatDt(dt) {
    def tf = new java.text.SimpleDateFormat("E MMM dd HH:mm:ss z yyyy")
    if(location?.timeZone) { tf.setTimeZone(location?.timeZone) }
    else {
        log.warn "SmartThings TimeZone is not set; Please open your ST location and Press Save"
    }
    return tf.format(dt)
}

def gitRepo()	        { return "BamaRayne/Echosistant"}
def gitBranch()		    { return "master" }
def getWikiPageUrl()	{ return "http://thingsthataresmart.wiki/index.php?title=EchoSistant" }
def getAppImg(imgName)	{ return "https://echosistant.com/es5_content/images/$imgName" }
