# Online Status Monitor Edge Driver
A SmartThings Edge device driver to monitor online/offline status of any SmartThings device

## Pre-requisites
This driver depends on having some kind of proxy available on your home network so that REST API requests can be sent to SmartThings.  This requirement can be satisfied with my [edgebridge application](https://github.com/toddaustin07/edgebridge).  If you already have edgebridge installed but have not created the optional configuration file, you WILL need to create that configuration file now in order to provide your SmartThings Token.

Additional requirements:
* An 'always-on' computer
* SmartThings Hub running Edge
* [SmartThings Bearer Token](https://account.smartthings.com/tokens)

## Installation & Configuration
### Edgebridge
Go to my github repository and follow the instructions to download and configure the application 
#### Edgebridge configuration file
The github README indicates the configuration file is optional, but for this driver it is mandatory because it must contain your SmartThings Token.  Create a file called edgebridge.cfg in the same directory as your edgebridge application file and edit it to look like this:
```
[config]
Server_Port = 8088
SmartThings_Bearer_Token = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```
The port number of 8088 is the default port used by edgebridge.  You can change this, but it must match the edgebridge address configured in any of your SmartThings device Settings that use it.

Include your *actual* SmartThings Token.  Be sure the token includes read authorization for locations and devices.

### Edge Driver
Enroll your hub in my test channel and select **Online Status Monitor V1** from the list of drivers to be installed.

Once the driver is available on your hub, the next time you perform an *Add device / Scan for nearby devices* in the mobile app, you will get a device created in your *No Room Assigned* room called "Online Status Monitor".  Open this device to the Controls screen and tap the 3 vertical dot menu in the upper right and then select **Settings**.

#### Device Settings
##### SmartThings Device ID
Here you need to provide the SmartThings device ID for the device you want to monitor.  The device ID can be obtained with the SmartThings CLI:
```
smartthings devices
```
Or through other ways to send an API command (Browser, Postman, curl, etc) (Note that the request will require an authorization header with your Bearer Token)
```
GET https://api.smartthings.com/v1/devices
```
You may be able to simply plug the above URL into a browser.  If you are already logged into a SmartThings website in another tab using your SmartThings authentication, the request may work without any explicit token header.  Note that in a browser, the device list JSON can be quite long, so there is probably a link at the bottom of the returned data for additional pages of data.  It is **highly** recommended to have a JSON formatter browser extension for easier reading.


##### Polling Interval
How often you want to ask SmartThings for the status of the device will depend on the urgency you need to be notified when it changes status.  There is a practical limit on the number and frequency of requests you can send to SmartThings before you exceed rate limits.  So the polling interval is given in number of **minutes**, with 1 minute as the most frequent allowed, and 10,080 as the least frequent (10,080 minutes == once a week).

##### Proxy Type
If you are using the edgebridge server, then this can be left to the default.  The 'custom' option is reserved for more advanced users.

##### Edge Bridge Address
The address must be given in the form of \<*IP*>:\<*port*>.  For example 192.168.1.140:8088.  The port number MUST be included.  8088 is the default port used by edgebridge, unless it is changed in the configuration file.

##### Custom Proxy Prefix
This field is reserved for advanced users with their own custom proxy solution.  It would include the local URL 'prefix' up to, but not including the SmartThings REST API endpoint.  For example:
```
http://192.168.1.n:ppppp/proxy/get?url=
```
## Usage
Once the device Settings are configured, polling will begin at the desired interval.  The status obtained is shown on the dashboard tile and Controls screen as either "online" or "offline".  This value is available to automations as well.

To force a refresh immediately, perform a swipe down motion on the Controls screen (standard 'refresh' gesture).  SmartThings will be immediately queried and the status value updated.

To create additional devices, use the 'Create additional device' button on the Controls screen.  Each individual device will need to be configured as above.

