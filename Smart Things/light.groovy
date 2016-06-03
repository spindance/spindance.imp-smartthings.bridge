metadata {
	definition (name: "ElectricImp Development Light Sensor", namespace: "swankdave", author: "David Meyer") {
		capability "Illuminance Measurement"
	}


	tiles {
		valueTile("illuminance", "device.illuminance") {
			state "luminosity", label:'${currentValue} ${unit}', unit:"lux"
		}
	}
}


def parse(String description) {
	log.debug "Parsing '${description}'"
    //sendEvent(name: "illuminance", value: Math.round(Double.parseDouble(description)), unit: "lux")
}

def update(illuminance) {
	sendEvent(name: "illuminance", value: Math.round(Double.parseDouble(illuminance)), unit: "lux")
}
