
function debugRequest(request){
    server.log("request:")
    server.log("\tmethod:\t"+http.jsonencode(request["method"]))
    server.log("\tpath:\t"+http.jsonencode(request["path"]))
    server.log("\tquery:\t"+http.jsonencode(request["query"]))
    server.log("\theaders:")
    foreach (key, value in request["headers"]) {
        server.log("\t\tKey: " + value);
    }
    server.log("\tbody:\t"+http.jsonencode(request["body"]))
    server.log("\n\n")
}

class SmartThingProxy{
    
    local_url            = "";    #The root url for this agent
    local_callback_url   = "";    #The address SmartThings needs to redirect our client to so we can get the token
    remote_url           = "";    #The root url for the SmartThings security api
    remote_authorize_url = "";    #Redirect the user here for the user to authorize our token
    remote_token_url     = "";    #Query here to trade the access token for the auth token
    remote_endpoints_url = "";    #Query here to get the root endpoint for api access
    http_handler_next    = false; #Specifys the next http handler method to try, if this class is unable to handle the request
    getSettings          = null;  #method handle for allowing the user to override how the library loads persisted information
    saveSettings         = null;  #method handle for allowing the user to override how the library persists information
    
    function myGetSettings(){
        if (!server.load())
            server.save({})
        return server.load();
    }
    
    function mySaveSettings(settings){
        server.save(settings)
    }
    
    constructor(localGetSettings = null, localSaveSettings = null, local_http_handler_next = null){
        getSettings = myGetSettings;
        saveSettings = mySaveSettings;
        
        if (localGetSettings)
            getSettings = localGetSettings;
        if (localSaveSettings)
            saveSettings = localsaveSettings;
        
        http_handler_next = local_http_handler_next  

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
        local settings = getSettings();
        settings.remote_client_id <- client_id;
        settings.remote_client_secret <- client_secret;
        saveSettings(settings)
    }
    
    #get endpoint for smart things SmartApp 
    function processEndPointResponse(incoming_data_table){
        local settings = getSettings();
        settings.remote_application_uri <- http.jsondecode(incoming_data_table["body"])[0]["uri"]
        saveSettings(settings)
    }
    
    #recieve and save Auth Token
    function processAuthTokenResponse(incoming_data_table){
        local settings = getSettings();
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
        local body = "<a href=\"" + redirect + "\">Click here to authroize imp to SmartThings</a>"; #just incase the redirect is rejected
        response.header("Location", redirect)
        response.send(302, body)
    }
    
    function requestHandler(request, response){
        local settings = getSettings();
        server.log(http.jsonencode(this));
        if (request["path"] == "/oauth/authorize"){
            collectSecureClientInfo(request["query"]["clientId"], request["query"]["clientSecret"]);
            redirectUserToSTAuth(response, settings.remote_client_id);
        } else if  (request["path"] == "/oauth/callback"){
            requestAuthToken(request["query"]["code"], settings.remote_client_id, settings.remote_client_secret)
            response.send(200, "Success")
        } else {
            if (http_handler_next)
                http_handler_next(request,response)
            else
                response.send(404, "could not find the page your looking for")
        }
    }
    
    function send(name,value){
        local settings = getSettings();
        http.get(settings.remote_application_uri + "/values/?name=" + name + "&value=" + value, {"Authorization" : "Bearer " + settings.remote_access_token}).sendasync(function(response){})
    }
}


function postReading(data) {
    server.log(http.jsonencode(data));
    smartThingProxy.send("thermostat1",data.temp);
    smartThingProxy.send("luminosity1",data.lux);
    smartThingProxy.send("humidity1",data.humid);
    smartThingProxy.send("barometer1",data.pressure);
}

smartThingProxy <- SmartThingProxy();
smartThingProxy.send("ValueName","NamedValue");
device.on("reading", postReading);
