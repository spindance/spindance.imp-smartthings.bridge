There are a myriad of Internet of Things (IoT) cloud and hardware providers out there, all competing to be the platform upon which you can build your next great gadget. Two of these providers are [Electric Imp](https://electricimp.com/) and [SmartThings](https://www.smartthings.com/). (now owned by [Samsung](http://www.samsung.com/)) These IoT providers have two very different approaches to the world of Iot:

## Electric Imp

*   Sells hardware targeted to developers($20)
*   Leverages the Squirrel programming language in an online development environment
*   Is geared towards supporting Electric Imp hardware
*   Has a cloud solution that is largely geared towards developers, and is not designed to have a customer facing UI. (not to say that it can't)
*   Has an offering to run an instance of their cloud on your equipment, protecting you in case they are bought out/go out of business etc.

## SmartThings

*   Sells hardware targeted to consumers (except the arduino shield($35))
*   Leverages the Groovy programming language in an online development environment
*   Is set up to talk to any hardware, provided the customer has the SmartThings hub($100)
*   Has a cloud solution that is largely geared towards developers, and has tools for designing a mobile UI that will be displayed in their mobile app
*   Will not privatize their cloud

Both systems have strengths and weaknesses, but I would like to focus on getting the strengths of both, and for that, I'm going to show you how to connect the two systems so that you can build a device with the electric imp, and support your users by incorporating it in to their existing SmartThings home configuration. Before taking any of the steps here, you will need both a [SmartThings account](https://graph.api.smartthings.com/), and an Electric Imp, with [account](https://ide.electricimp.com/login). (both of which are free, provided you have their hardware) I would give directions on how to [BlinkUp](https://electricimp.com/docs/gettingstarted/blinkup/) the Electric Imp module, (how you claim ownership of the module) or [setup the SmartThings hub](https://support.smartthings.com/hc/en-us/articles/205380614-How-to-set-up-the-Hub), but its a simple process that is widely documented already.

## Establishing Aauthentication

Another process that is documented, though not well in this context, is the flow of OAuth token exchange. In this case the workflow will eventually go something like this.

1.  User starts out logged in to the SmartThings mobile Application (SmartThings doesn't really have a customer focused web UI)
2.  User enters the address of their Electric Imp agent, and SmartThings directs the user's web browser to that address, with identifying tokens to use for authentication to the SmartThings Authentication Server in the request query string. (The only way to pass data from one domain to another through a user because of CORS restrictions)
3.  The Electric Imp agent redirects the user to the SmartThings authentication server with the identification tokens, and an address to forward the user to after they have been authenticated.
4.  The user is prompted by the SmartThings authentication server for their username and password, and then asked if they would like to give the source domain (Electric Imp) access to their information within the SmartThings system
5.  Upon the user approving the source domain for access, the user is redirected back to Electric Imp with a temporary authentication token in the query string
6.  Electric Imp then independently calls SmartThings web services directly to exchange the authentication token for an access token (the authentication token is short lived and single use, and the access token is more secure because it is only ever shared between servers)
7.  Electric Imp then independently calls SmartThings web services directly to get the list of available web services and their addresses for this token

Don't worry about this process for now, but refer to it if you get lost and aren't sure where this is headed. Once you have accounts and devices sorted out with SmartThings and Electric Imp, we will start on the Electric Imp side of things, so that the redirect in step 2 has a place to land. Log in to the [Electric Imp IDE](https://ide.electricimp.com) and create a new Development Model. Development models are the equivalent of a project in other systems, but its much more prescriptive in that it only has two files: an Agent file and a Device file. For now we can ignore the Device side, and just focus on the Agent side. The agent is the part of the Imp that runs on the cloud. Within Electric Imp's system, its mainly there to support the operations of the Imp, but it is available to accept HTTP requests. Create a class that can accept an HTTP request, and an instance of that class:

```
class SmartThingProxy{
    constructor(){
        http.onrequest(requestHandler.bindenv(this));
    }

    function requestHandler(request, response){
        server.log("\tpath:\t"+http.jsonencode(request["path"]))
    }
}

smartThingProxy <- SmartThingProxy();
```

The code above initiates an object of type SmartThingProxy, which in turn, (in its constructor) registers its function requestHandler as a listener for requests made of the agent by the http web service. Squirrel is unique in that it assumes that all function calls are on class methods. Unless otherwise specified, like we did in the call requestHandler.bindenv(this), which bound the method call requestHandler to "this". (our instance of SmartThingProxy) If you go to the address listed next to the word agent, at the top of the left development pane in the Electric Imp IDE... nothing will happen in your web browser. Something will happen however, in the logs for your electric imp: It should display "path:" along with the full path you entered to reach your agent. The logs are at the bottom of the screen, accessible by hitting the small arrow pointing up at the bottom of the screen. Now that we have proof that we can communicate between our web browser and the Imp Agent, we can build on this by building our own http request router within the Agent.


```
function requestHandler(request, response){
        if (request["path"] == "/oauth/authorize")
            response.send(200, "you found me!")
        else
            response.send(404, "could not find the page your looking for")
    }
```

This code will check the request object and respond with a friendly 200 if the user requests the /oauth/authorize page, and 404 otherwise. It is important to be able to accept web requests so that we can facilitate the workflow for authenticating Electric Imp to the SmartThings Cloud. Now that we can accept requests on the Electric Imp side, lets switch over to SmartThings and create a Smart App to communicate with.

### Steps 1&2

To create a SmartApp, log in to [SmartThings](https://graph.api.smartthings.com/), and navigate to "My Smart Apps". once there, select "New Smart App" (in the upper right) and fill out the form to name and categorize your app. at the bottom of the form there will be a button: "Enable OAuth". Click on that button, and copy the numbers it gives you, as you will need them to set up the authentication request for the Electric Imp. Then click create. Once you have a skeleton smart app, it's definition section will look something like this:

```
definition(
    name: "Electric Imp (Connect)",
    namespace: "smartthings",
    author: "David.Meyer@SpinDance.com",
    description: "Connect your Electric Imp to SmartThings.",
    category: "SmartThings Labs",
    singleInstance: true,
    oauth: [ displayName: "Electric Imp (Connect)"]
){}
```

For this example, it may be useful to set singleInstance: true, at least while the app is under development, otherwise, during testing you will install hundreds of copies of the same app. For the root preferences menu, we can use the following

```
//Main preferences page
preferences {
    def clientId = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
    def clientSecret = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
    def ImpAgentUrl = "https://agent.electricimp.com/XXXXXXXXXXXX"

    page(name:"Main", title:"Electric Imp Settings", install: true, uninstall: true){
        section (){
            href(
                name: "ElectricImpAuthLink",
                title: "Start Authentication Process",
                style: "external",
                url: "$ImpAgentURL/oauth/authorize?clientId=$clientId&clientSecret=$clientSecret",
                description: "Tap here to authorize Electric Imp to talk to SmartThings.  This may take up to 30 sec to load."
            )
        }
    }
    page(name: "impSubmit", title: "Configure and Authenticate")
}
```

This establishes the root preferences page, with a link to the ImpAgent, with the client id and client secret necessary to establish authentication. Earlier, when we created this app, I told you to note the OAuth client id and client secret, they go in this function (in place of XXX) as well as the link to your Electric Imp agent. Now its time to test and see if our application is ready. Ensure that in both Electric Imp and SmartThings your programs are checked, saved, published and running. In theory, you should be able to run your SmartApp on the simulator in the SmartThings IDE, but I have yet to see external links working in the simulator, so skip that for now and instead use a mobile device with the SmartThings App installed. **(Step 1)** Once in the SmartThings app, goto Marketplace->Apps->MyApps and run the app you just wrote. it should just be the one link, that link should open a page with the text "you found me!" **(step 2)** We have now successfully completed step 2 from the process outline. Step 3 is simple: redirect the request from the users browser back to SmartThings, with the client id, client secret, and a link back to our Imp Agent.

### Steps 3, 4 and 5

To accomplish this, (in the Imp Agent in the Electric Imp IDE) we need only read a few values from the request object in our requestHandler method, and use them to assemble the URL for the SmartThings authentication server, and return that URL along with a HTTP response code 302 (redirect) to the users browser. This is done by updating our requestHandler method like so...

```
function requestHandler(request, response){
        local remote_url = "https://graph.api.smartthings.com"
        local remote_authorize_url = remote_url + "/oauth/authorize"
        if (request["path"] == "/oauth/authorize"){
            local redirect = remote_authorize_url + "?" +
                http.urlencode({
                    response_type = "code"
                    client_id = request["query"]["clientId"]
                    scope="app"
                    redirect_uri = local_callback_url
            })
            response.header("Location", redirect)
            response.send(302, body)
        }else
            response.send(404, "could not find the page your looking for")
    }
```

The above code assembles the redirect URL and sends the response back to the user's browser. **(step 3)** If you run the above, and then try the link from the SmartThings app on your mobile device, (the link in the app you wrote in SmartThings for steps 1&2) you should find yourself being prompted to log in to the SmartThings website to give permission for Electric Imp to access your data in the SmartThings cloud. **(Step 4)** If you give permission, the SmartThings website will then redirect you back to the address we provided in the redirect. **(Step 5)** SmartThings handled steps 4 and 5 and we didn't even have to do anything! At this point, we are now getting a 404 from our Electric Imp Agent, because we haven't told it how to deal with the page we redirected ourselves to from the authentication server at SmartThings. This is easily done, by adding a clause to our request handler function to handle the page address. while we are adding this, lets refactor our request handler to clean it up.

```
class SmartThingProxy{

    local_url            = "";    #The root url for this agent
    local_callback_url   = "";    #The address SmartThings needs to redirect our client to so we can get the token
    remote_url           = "";    #The root url for the SmartThings security api
    remote_authorize_url = "";    #Redirect the user here for the user to authorize our token
    remote_token_url     = "";    #Query here to trade the access token for the auth token
    remote_endpoints_url = "";    #Query here to get the root endpoint for api access

    constructor(){
        if (!(server.load()))
            server.save({})

        local_url = http.agenturl()
        local_callback_url = local_url + "/oauth/callback"
        remote_url = "https://graph.api.smartthings.com"
        remote_authorize_url = remote_url + "/oauth/authorize"
        remote_token_url = remote_url + "/oauth/token"
        remote_endpoints_url = remote_url + "/api/smartapps/endpoints"

        http.onrequest(requestHandler.bindenv(this));
    }

    #collects and stores clientId and clientSecret
    function collectSecureClientInfo(client_id, client_secret){
        local settings = server.load();
        settings.remote_client_id <- client_id;
        settings.remote_client_secret <- client_secret;
        server.save(settings)
    }

    #get endpoint for smart things SmartApp
    function processEndPointResponse(incoming_data_table){
        local settings = server.load();
        settings.remote_application_uri <- http.jsondecode(incoming_data_table["body"])[0]["uri"]
        server.save(settings)
    }

    #recieve and save Auth Token
    function processAuthTokenResponse(incoming_data_table){
        local settings = server.load();
        local access_token = http.jsondecode(incoming_data_table.body)["access_token"]
        settings.remote_access_token <- access_token
        server.save(settings)
        http.get(remote_endpoints_url, { "Authorization" : "Bearer " + access_token })
            .sendasync(processEndPointResponse.bindenv(this))
    }

    #exchange Access token for Auth Token
    function requestAuthToken(token, remote_client_id, remote_client_secret){
        local url = remote_token_url + "?" +
            http.urlencode({
                grant_type = "authorization_code"
                code = token
                client_id = remote_client_id
                client_secret = remote_client_secret
                redirect_uri = local_callback_url
            })
        http.post(url, {"content-type" : "application/x-www-form-urlencoded"}, "")
            .sendasync(processAuthTokenResponse.bindenv(this))
    }

    //bounces user to Smart Things Oauth, after which the user will be bounced back to this service
    function redirectUserToSTAuth(response, client_id){
        local redirect = remote_authorize_url + "?" +
            http.urlencode({
                response_type = "code"
                client_id = client_id
                scope="app"
                redirect_uri = local_callback_url
            })
        response.header("Location", redirect)
        response.send(302, "")
    }

    function requestHandler(request, response){
        local settings = server.load();
        if (request["path"] == "/oauth/authorize"){
            collectSecureClientInfo(request["query"]["clientId"], request["query"]["clientSecret"]);
            redirectUserToSTAuth(response, settings.remote_client_id);
        } else if  (request["path"] == "/oauth/callback"){
            requestAuthToken(request["query"]["code"], settings.remote_client_id, settings.remote_client_secret)
            response.send(200, "Success")
        } else {
            response.send(404, "could not find the page your looking for")
        }
    }
}

smartThingProxy <- SmartThingProxy();
```

From the requestHandler method (last method in the class), you can see that we are still handling the '/oauth/authorize' url, and that we are now saving the Client ID and Client Secret off as a local resource

`collectSecureClientInfo(request["query"]["clientId"], request["query"]["clientSecret"]);`

before we redirect the user to the SmartThings authentication server.

`redirectUserToSTAuth(response, settings.remote_client_id);`

Upon the users return, they land at '/oauth/callback'. From that request, we collect the authentication token (or 'code', as SmartThings calls it) and call the SmartThings authentication service directly to exchange the authentication token for an access token, **(Step 6)** which is then stored by the Electric Imp Agent.

`requestAuthToken(request["query"]["code"], settings.remote_client_id, settings.remote_client_secret)`

That command, in turn, asynchronously kicks off a request for the web service endpoint the Electric Imp Agent is supposed to use, and what capabilities it has from that endpoint. **(Step 7)**

```
http.get(remote_endpoints_url, { "Authorization" : "Bearer " + access_token })
            .sendasync(processEndPointResponse.bindenv(this))
```

It does this asynchronously by allowing us to provide a method and context to use as a callback when the call returns. Steps 6 and 7 are now complete. One thing of note here is that the call to retrieve the SmartThings web service endpoint for the SmartApp we are writing requires our security credentials, which we present in the request header by specifying: "Authorization" : "Bearer " + access_token. This header will be required for all communications with SmartThings moving forward for this system instance. Normally these access tokens expire and must be refreshed frequently, by presenting a refresh token, however SmartThings has configured their tokens to not expire for 50 years, so you will probably be ok not worrying about refreshing the access token.

## Sending Data

In order to access data from our Electric Imp in SmartThings, we now need to define an endpoint within our SmartApp so that it can receive and process data. This is accomplished by including the following in the SmartApp:

```
//The address the Electric Imp writes to to update its virtual devices
mappings {
    path("/values/:name:value") {
        action: [GET: "updateValue"]
    }
}

def updateValue() {
    log.debug("Name: " + params.name + " Value: " + params.value)
}
```

This establishes the updateValue method as the handler for all web service requests to "/values/" that contain name and value in the query parameters.  The updateValue method writes to the system log. (a tab at the top of the SmartThings page) Back on the Electric Imp side of things, if we add the following to our SmartThingProxy class, we will have a method that we can call to post name/value combinations to our SmartApp.

```
function send(name,value){
        local settings = server.load();
        http.get(settings.remote_application_uri + "/values/?name=" + name + "&value=" + value, {"Authorization" : "Bearer " + settings.remote_access_token}).sendasync(function(response){})
    }
```

Now we can post from the Electric Imp agent to our SmartApp by calling

`smartThingProxy.send("ValueName","NamedValue");`

Congratulations, you now have an Electric Imp device that reports values to SmartThings. [Here](https://github.com/spindance/spindance.imp-smartthings.bridge) is the next incantation of the code from this tutorial, which includes the code for the Electric Imp Environment Tail, as well as code for the SmartApp to allow the creation of virtual devices on the SmartThings cloud and write the values from the Electric Imp to those virtual devices.
