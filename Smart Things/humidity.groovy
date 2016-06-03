metadata {
	definition (name: "ElectricImp Development Humidity Sensor", namespace: "swankdave", author: "David Meyer") {
		capability "Relative Humidity Measurement"
	}

	tiles {
		valueTile("humidity", "device.humidity") {
			state "humidity", label:'${currentValue}%', unit:""
		}
	}
}

def parse(String description) {
	log.debug "Parsing '${description}'"
}
def update(humidity) {
	sendEvent(name: "humidity", value: Math.round(Double.parseDouble(humidity)), unit: "%")
}