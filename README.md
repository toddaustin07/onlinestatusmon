# Online Status Monitor Edge Driver
A SmartThings Edge device driver to monitor online/offline status of SmartThings devices

## Pre-requisites
This driver depends on having some kind of proxy available on your home network so that REST API requests can be sent to SmartThings from the Edge driver.  This requirement can be satisfied with my [edgebridge application](https://github.com/toddaustin07/edgebridge).  If you already have edgebridge installed but have not created the optional configuration file, you WILL need to create that configuration file now in order to provide your SmartThings Token (see below).

Additional requirements:
* An 'always-on' computer
* SmartThings Hub running Edge
* [SmartThings Bearer Token](https://account.smartthings.com/tokens)
* List of **SmartThings device IDs** (UUID format) of the devices you want to monitor (see below for more info)

### Finding the SmartThings device ID

Device IDs can be obtained in a few ways:
* Option 1: Use a web browser, curl or Postman
  * Depending on what you use, the request may require a way to include an authorization header with your SmartThings Token
  * A browser can be the easiest, but it is **highly** recommended to have a JSON formatter browser extension for easier reading of the response data.
  * If you sign in to your SmartThings account in another tab of your browser, you may be able to simply type the URL below in another tab and have your authorization be recognized:
    ```
    https://api.smartthings.com/v1/devices
    ```
    If you get a 401 error, you need to get signed in to your SmartThings account on another tab.
* Option 2: Use SmartThings CLI:
  ```
  smartthings devices
  ```
  
A device ID is a 36-character hexidecimal string in the standard UUID format:  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  
*Note that the Device IDs required for this driver are **not** available from the IDE (soon to be sunset)*

## Installation & Configuration
### Edgebridge
Go to my github repository and follow the instructions to download and configure the edgebridge application.
#### Edgebridge configuration file
The edgebridge github README indicates the configuration file is optional, but for this driver it is mandatory because it must contain your SmartThings Token.  Create a file called edgebridge.cfg in the same directory as your edgebridge application file and edit it to look like this:
```
[config]
Server_Port = 8088
SmartThings_Bearer_Token = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```
The port number of 8088 is the default port used by edgebridge.  You can change this, but it must match the edgebridge address configured in any of your SmartThings device Settings that use it.

Include your *actual* SmartThings Token.  

##### Creating a SmartThings Token
If you do not already have a Smartthings token, you can create one [here](https://account.smartthings.com/tokens).  At minimum, include authorization for reading locations and devices.  Once it has been created, be sure to copy and paste your assigned token into a safe place, as well as into the edgebridge.cfg file.

Be sure your edgebridge.cfg is in the same current working directory as your edgebridge app.

Once you have completed and saved your edgebridge.cfg file, you must start (or restart) edgebridge, for example:
```
Any OS with Python:  python3 edgebridge.py
Windows: edgebridge.exe
Raspberry Pi:  ./edgebridge4pi
```

### Edge Driver
Enroll your hub in my [shared projects](https://bestow-regional.api.smartthings.com/invite/d429RZv8m9lo) channel and select **Online Status Monitor V1g** from the list of drivers to be installed.

Once the driver is available on your hub, the next time you perform an *Add device / Scan for nearby devices* in the mobile app, you will get a device created in your *No Room Assigned* room called "Online Status Monitor".  Open this monitoring device to the Controls screen and tap the 3 vertical dot menu in the upper right and then select **Settings**.

#### Grouping devices to monitor

Before you continue you will need to understand that this new device you just created is designed to provide monitoring for **up to 19 distinct SmartThings device IDs**.  You will also be able to create *additional* monitoring devices, each of which can contain up to *19 more* device IDs for monitoring.  In this way, you can group your devices for monitoring and avoid having to create one monitoring device for each and every device you want to monitor, which would cause a proliferation of SmartThings devices.  However, you may prefer to configure only one device ID per SmartThings monitoring device so that you can label the device for ease of use - both in the Controls screen and in managing automations.  This will all make more sense after you configure your first few devices.

#### Device Settings

##### Polling Interval
How often you want to ask SmartThings for the status of the device IDs configured will depend on the urgency you need to be notified when it changes status.  There is a practical limit on the number and frequency of requests you can send to SmartThings before you exceed rate limits.  So the polling interval is given in number of **minutes**, with 1 minute as the most frequent allowed, and 10,080 as the least frequent (10,080 minutes == once a week).

Note that this value can be changed at any time and will take effect immediately.

##### Proxy Type
If you are using the edgebridge server, then this can be left to the default.  The 'custom' option is reserved for more advanced users.

##### Edge Bridge Address
The address must be given in the form of \<*IP*>:\<*port*>.  For example 192.168.1.140:8088.  The port number MUST be included.  8088 is the default port used by edgebridge, unless it is changed to something else in the edgebridge.cfg file.

##### Custom Proxy Prefix
This field is reserved for advanced users with their own custom proxy solution.  It would include the local URL 'prefix' up to, but not including the SmartThings REST API endpoint.  For example:
```
http://192.168.1.n:ppppp/proxy/get?url=
```
*Note that it is the custom proxy's responsibility to include an https Authorization header with your SmartThings token.*
##### SmartThings DeviceIDs (#1-19)
Here you need to provide the SmartThings device IDs for each of the devices you want to monitor.  

You can provide as few or as many device IDs as you would like (up to 19) and configure them in any available 'slot'.

Device IDs must be provided in the standard UUID hexidecimal format (36 characters): xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.  Any values not conforming to this standard will be ignored.

##### Short Device Name (#1-19)

In addition to the device ID itself, you can optionally provide a short (20 alphanumeric characters, no spaces, so special characters) name for the device that will be shown on the Controls screen to aid in remembering which device is which.  Note that this name will *not* appear in the Automations screen.


## Usage
Once a valid edgebridge address and at least one device ID is configured, polling will begin at the desired interval.  The status obtained is shown in the respective device section on the Controls screen as either "online" or "offline".  This status may also be prefixed by the short device name if provided in device Settings.  The online/offline device status is available to automations as well.

To force a refresh immediately, perform a swipe down motion on the Controls screen (standard 'refresh' gesture).  SmartThings will be immediately queried and the status values updated.

To create additional devices, use the 'Create additional device' button at the top of the Controls screen.  Each individual device will need to be configured as above, with its own list of devices and a unique polling interval.  In fact this may be one way you may want to group your devices, with some having a polling interval more or less frequent than others.


## Not Working
* Is your edgebridge address configured correctly?
* Is your edgebridge app running and available at the configured address?
* Is your SmartThings Token correctly configured in edgebridge.cfg?  Stop and restart edgebridge with any config file changes
* Did you provide the right device ID?  Copy and pasting is the safest way to go; it must be exactly 36 characters or will be ignored
  * If manually entered, take care with 'l' vs '1' and 'O' vs. '0', etc.
  * Ensure there are no inadvertent leading or trailing spaces
