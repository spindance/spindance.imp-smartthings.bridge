metadata {
	definition (name: "ElectricImp Development Barometeric Sensor", namespace: "swankdave", author: "David Meyer") {
		capability "Sensor"
	}
    tiles {
        valueTile("pressureTile", "device.value") {
                  state "pressure", label:'${currentValue} MMHg'
        }
    }
}

def parse(String description) {
	log.debug "Parsing '${description}'"
}

def update(pressure) {
	sendEvent(name: "value", value: Math.round(Double.parseDouble(pressure)), unit: "")
}