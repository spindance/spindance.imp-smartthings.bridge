metadata {
	definition (name: "ElectricImp Development Temperature Adapter", namespace: "Swankdave", author: "David Meyer", oauth: true) {
		capability "Temperature Measurement"
		command "update"
	}
	tiles {
        valueTile("temperature", "device.temperature") {
            state("temperature", label:'${currentValue}°',
                backgroundColors:[
                    [value: -1, color: "#153591"],
                    [value: 7, color: "#1e9cbb"],
                    [value: 15, color: "#90d2a7"],
                    [value: 23, color: "#44b621"],
                    [value: 29, color: "#f1d801"],
                    [value: 35, color: "#d04e00"],
                    [value: 36, color: "#bc2323"]
                ]
            )
        }
	}
}

def parse(String description) {
	log.debug "Parsing '${description}'"
    //sendEvent(name: "temperature", value: Math.round(Double.parseDouble(description)), unit: "C")
}

def update(temperature) {
	sendEvent(name: "temperature", value: Math.round(Double.parseDouble(temperature)), unit: "C")
}
