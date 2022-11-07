load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/json.star", "json")

TIDBYT_OAUTH_CALLBACK_URL = "http%3A%2F%2Flocalhost%3A8080%2Foauth-callback"

DEXCOM_CLIENT_ID = "d9vtCJPnaZ5IVMSx8KbAqPZSOOcq6hO2"
DEXCOM_CLIENT_SECRET = "xxxxxxxxxxxx"
DEXCOM_OAUTH_AUTHORIZATION_URL = "https://api.dexcom.com/v2/oauth2/login?client_id={DEXCOM_CLIENT_ID}&redirect_uri={TIDBYT_OAUTH_CALLBACK_URL}&response_type=code&scope=offline_access".format(DEXCOM_CLIENT_ID=DEXCOM_CLIENT_ID, TIDBYT_OAUTH_CALLBACK_URL=TIDBYT_OAUTH_CALLBACK_URL)
DEXCOM_OAUTH_TOKEN_URL = "https://api.dexcom.com/v2/oauth2/token"

def main(config):
    token = config.get("auth")

    if token:
        msg = "Authenticated"
    else:
        msg = "Unauthenticated"

    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )

def oauth_handler(params):
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
    }
    params = json.decode(params)
    body = (
        "grant_type=authorization_code" +
        "&client_id=" + params["client_id"] +
        "&client_secret=" + DEXCOM_CLIENT_SECRET +
        "&code=" + params["code"] +
        "&scope=offline_access" + 
        "&redirect_uri=" + params["redirect_uri"]
    )

    response = http.post(
        url = DEXCOM_OAUTH_TOKEN_URL,
        headers = headers,
        body = body,
    )

    if response.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (response.status_code, response.body()))

    token_params = response.json()
    refresh_token = token_params["refresh_token"]

    return refresh_token

def get_schema():
    print(DEXCOM_OAUTH_AUTHORIZATION_URL)
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Dexcom",
                desc = "Connect your Dexcom account.",
                icon = "github",
                handler = oauth_handler,
                client_id = DEXCOM_CLIENT_ID,
                authorization_endpoint = DEXCOM_OAUTH_AUTHORIZATION_URL,
                scopes = [
                    "offline_access",
                ]
            )
        ]
    )