# [spindance.imp-smartthings.bridge](https://github.com/spindance/spindance.imp-smartthings.bridge)

This project is setup as an example for how to integrate web services from [Electric Imp](https://electricimp.com/) and [SmartThings](https://www.smartthings.com/).  

## Requirements
Before you can make use of this project, you will need a developer login for both Electric Imp, and Smart Things.  Both resources are free, though you may need valid hardware. (SmartThings Hub and Electric Imp001)

## Contents
This project consists of 2 parts: Electric Imp, and Smart Things, in their respective folders.  
Both systems are online IDE's.  To load the files in to the IDE's, they will need to be copied and pasted in to their respective device types and windows.
Both Directories also include a file: swagger.json.  That file can be loaded in to a swagger api documentation engine to give a better idea of what web services are involved in the calls.  If you can supply the client_id and client_secret, you can even make those calls from swagger, or it can auto-generate code to make those calls in the language of your choice.

## Running
To run this code, create a new SmartApp on SmartThings, and paste SmartApp.groovy in to the SmartApp window, then create a new application in Electric Imp and paste Agent.nut (from the Electric Imp folder) in to the agent window within Electric Imp's IDE. There are more steps that need to be done, but they are well documented in the article (article.md or on momentium.spindance.com) so check there.

## About

### [SpinDance](http://spindance.com)
We design and develop fully integrated, custom software systems that bring products to life with elegant, compelling user experiences.  Our goal is to make you successful. We combine our agile development approach with techniques like automated testing and continuous delivery to facilitate constant collaboration and feedback, so you can ensure that we’re building the right thing, the right way.

### David Meyer
Dave is an Inventor, Developer and Snappy Dresser.  Dave has a bachelors in Computer Science from Calvin College and is currently working on his masters at GVSU.  Dave loves the thrill of discovery, design and problem solving. He finds expressing solutions through software, hardware, or mechanical prototyping to be the highpoint of his day.  It was the ability to invent with software that originally drew him to the field, and loves learning the new ways of thinking embedded in different software languages and technologies.
