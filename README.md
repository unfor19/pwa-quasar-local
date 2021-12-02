# pwa-quasar-local

This project demonstrates how to develop a [Progressive Web Application](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps) (PWA) locally on an Android device, using the [Quasar Framework v2](https://quasar.dev/).

The main goal is to run an application in hot-reload mode, and make it available to a physical Android device. I'm using Android (Samsung Galaxy S10, [Android 11](https://en.wikipedia.org/wiki/Android_11)), but I'm sure there's a way to tweak this project to make it work on iOS.

## Challenges

This is how it all happened - documenting my learning process for future me

1. I wanted to know if a PWA can send [Push Notifications](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Re-engageable_Notifications_Push), like a normal application. For example, if the device is locked up and quiet, will it ring and buzz? Will I get notification from the PWA?
2. To make it work, I wanted to have a local development environment in [hot-reload mode](https://quasar.dev/quasar-cli/developing-pwa/hmr-for-dev), so I can test the PWA on an Android device as the code changes. Previously mentioned, I'm on Samsung Galaxy S10, [Android 11](https://en.wikipedia.org/wiki/Android_11), so if you're using a different Android device or version, make sure to Google for the "deltas".
3. The [requirements for running a PWA](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Installable_PWAs#requirements) are very restricting when it comes to HTTPS and local development. Quasar makes it possible to use [HTTPS for local development out-of-the-box](https://quasar.dev/quasar-cli/quasar-conf-js#property-devserver). Unforuneately, the [HTTPS trick works for https://localhost](https://blog.filippo.io/mkcert-valid-https-certificates-for-localhost/), so how can an Android device access this "local network address" and load the PWA? I have a way to mask `localhost` with a desired domain so it'll be `https://test.meirg.co.il`, but that still doesn't solve the problem of making it accesible to other devices on the local network.
4. Let's get to business

## Requirements

1. [NodeJS v14.17.0+](https://nodejs.org/en/download/current/)
2. [yarn](https://classic.yarnpkg.com/lang/en/docs/install)
   ```bash
   npm install --global yarn && \
   yarn --version
   ```
3. [quasar cli](https://quasar.dev/quasar-cli/installation) - see [yarn global](https://classic.yarnpkg.com/en/docs/cli/global/) if you're using [nodemon](https://www.npmjs.com/package/nodemon)
   ```bash
   yarn global add @quasar/cli
   ```
4. [Google Chrome](https://www.google.com/chrome/) for viewing the PWA and [controlling remote devices](https://developer.chrome.com/docs/devtools/remote-debugging/), such as the target Android device.
4. (Optional) I'm using [Visual Studio Code](https://code.visualstudio.com/), which makes the whole development process very easy. Especially the linting and auto-formatting.

TODO: Add Dockerfile

## PWA with hot-reload via HTTP

Before you read along, this project is the final artifact of the below steps. You can clone/fork this project, or even generate a GitHub repository from this project, and simply move on to the [Usage](#usage) section.

1. Generate a [PWA project](https://quasar.dev/quasar-cli/developing-pwa/preparation) with Quasar
   ```bash
   quasar create awesome-pwa
   ```
   1. Project name: `awesome-pwa`
   2. Project product name: `Awesome PWA`
   3. Project description: `Testing PWA on a physical Android device`
   4. Author: `firstName lastName <email@address.com>`
   5. Pick your CSS preprocessor: `Sass with SCSS syntax`
   6. Check the features needed for your project:
      1. `ESLint`
      2. `TypeScript` - make sure to select TypeScript with `<space>` and only then hit `<enter>`
   7. Pick a component style: `Composition API`
   8. Pick an ESLint preset: `Prettier`
   9. Continue to install project dependencies after the project has been created? `Yes, use Yarn`
2. From now on the **working directory should be awesome-pwa**
3. [Add PWA to the project](https://quasar.dev/quasar-cli/developing-pwa/preparation) with
   ```bash
   quasar mode add pwa
   ```
   ```
   ...
   App • Creating PWA source folder...
   App • Copying PWA icons to /public/icons/ (if they are not already there)...
   App • PWA support was added
   ```
4. Run the application locally in hot-reload mode
   ```bash
   quasar dev --mode pwa
   ```
5. Browser should be automatically opened, serving [http://localhost:8080/#/](http://localhost:8080/#/). This is the application running locally on your machine, and any code change will immediately be applied to the app.
6. To make sure [Service Workers](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers) are loaded properly, set the browser settings for the application: 
   1. Navigate to [http://localhost:8080/#/](http://localhost:8080/#/)
   2. [Open Chrome DevTools](https://developer.chrome.com/docs/devtools/open/#last)
   3. Application > Service Workers > Tick [Bypass for network](https://whatwebcando.today/articles/use-chrome-dev-tools-switches/)

## Setup A Local DNS Server

1. We need a local DNS server to trick everyone on the local network to think that `https://meirg.co.il.test` is actually my local machine network address, which is `192.168.0.5` at the moment of writing.
2. I chose [dnsmasq](https://wiki.debian.org/dnsmasq) for the job, but I'm sure any other option is valid. On macOS, use [brew](https://formulae.brew.sh/) to install [dnsmasq](https://formulae.brew.sh/formula/dnsmasq). If you're on Windows, I suggest you use [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) (TODO: Add docs for WSL2)
   ```
   brew install macOS
   ```
3. Check your local machine network IP address
   ```bash
   ipconfig getifaddr en0
   # Mine is 192.168.0.5
   ```
4. Edit dnsmasq config, and add map a domain to your local network address
   ```bash
   vim /usr/local/etc/dnsmasq.conf
   ```

   ```bash
   # Maps a local ".test" domain to the local network ip address of the current machine
   # Make sure to use ".test" as a suffix
   # Change "meirg.co.il" with your domain and "192.168.0.5" with your local network IP address
   address=/meirg.co.il.test/192.168.0.5
   ```
5. Map the local domain `meirg.co.il.test` to our local machine `192.168.0.5`
   - macOS - Create the directory "test" under /etc/resolver, see https://vninja.net/2020/02/06/macos-custom-dns-resolvers/ - any domain under `*.test` will resolve to `192.168.0.5` which is 
      ```bash
      sudo mkdir -p /etc/resolver/test
      ```
   - WSL2/Linux - Edit `/etc/hosts` file
      ```bash
      meirg.co.il.test 192.168.0.5
      ```
6. Restart `dnsmasq` by stopping and starting it
   - macOS
      ```bash
      sudo brew services stop dnsmasq
      sudo brew services start dnsmasq
      ```
7. Flush (refresh) DNS
   - macOS
      ```
      sudo killall -HUP mDNSResponder
      ```
8. Check your local DNS server
   ```bash
   # This is what happens when you use the default DNS server
   dig meirg.co.il.test # returns a.root-servers.net. nstld.verisign-grs.com. 2021113002 1800 900 604800 86400

   # And now via dnsmasq local DNS server
   dig meirg.co.il.test @192.168.0.5 # returns 192.168.0.5
   ```

## Access PWA From Local Machine

Assuming `quasar dev -m pwa` is running in the background.

Everything is already set, all you gotta' do is open Google Chrome and navigate to [http://meirg.co.il.test:8080](http://meirg.co.il.test:8080)

## Access PWA From An Android Device

Assuming `quasar dev -m pwa` is running in the background.

All the following steps are done on the Android device.

1. Set your Android Device DNS settings, so it will resolve use `192.168.0.5` as the DNS server. 
   1. Open WIFI settings and change the DHCP settings from Auto to Manual. 
   2. Set the first DNS server records to
      1. `192.168.0.5` (the local machine which is running `dnsmasq` local DNS server)
      2. `1.1.1.1` ([Cloudflare DNS](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/))
2. Open Google Chrome and navigate to [http://meirg.co.il.test:8080](http://meirg.co.il.test:8080/#/), the PWA should be accessible and will reload upon changing
3. That's nice, though it's not why we're here for. Since the application is served via HTTP and **not** HTTP**S**, the app is not classified as PWA by the Android device. All the cool features of [add-to-home-screen](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Add_to_home_screen) (A2HS) and [push-notification](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Re-engageable_Notifications_Push) won't be available until we set HTTPS.

## Set An HTTPS Connection From Local Machine To PWA

First, I need a few things

1. CA.key - The private key of the [Certification Authority](https://www.ssl.com/faqs/what-is-a-certificate-authority/#:~:text=A%20certificate%20authority%20(CA)%2C,the%20issuance%20of%20electronic%20documents) (CA).
2. CA.pem - The CA **certificate**, installed on local machine (macOS/Linux/WSL2)
3. CA.der.pem - The [DER format](https://knowledge.digicert.com/quovadis/ssl-certificates/ssl-general-topics/what-is-der-format.html#:~:text=DER%20files%20are%20digital%20certificates,of%20the%20ASCII%20PEM%20format.&text=A%20DER%20file%20should%20not,often%20used%20with%20Java%20platforms.) of the CA **certificate**, which will be installed on the Android device.

The **standard** process is

![ca-diagram](https://d1smxttentwwqu.cloudfront.net/wp-content/uploads/2019/07/ca-diagram-b.png)

> Image Source: [https://www.ssl.com/faqs/what-is-a-certificate-authority/](https://www.ssl.com/faqs/what-is-a-certificate-authority/)

Though in our case, we skip the CSR and hardcode the domain in the CA certificate

1. I've created a convinience script which does the following
   1. Creates the directory [awesome-pwa/.certs](./awesome-pwa/.certs), this directory **should not be committed** to this repo.
   2. Generates the required files `CA.key`, `CA.pem`, `CA.crt` (per domain) and the converted format `CA.der.crt` to be installed on the Android device. The script is based on this [stackoverflow answer](https://android.stackexchange.com/a/238859/363870)
2. Run the convinient script to generate the required files
   ```bash
   # Replace domain name
   ./scripts/generate_ca.sh "meirg.co.il"
   ```
3. The next step is to tell Quasar's `devServer` [awesome-pwa/quasar.conf.js](./awesome-pwa/quasar.conf.js) to serve HTTPS and use the generated CA certificate and rootCA key.
   ```js
    devServer: {
      https: {
        cert: '.certs/meirg.co.il.test.crt',
        key: '.certs/rootCA.key',
      },
      port: 443,
      open: false
    },
   ```
4. The final step is to install the generated `meirg.co.il.test.crt` certificate on your local machine so it can trust the certificate that the PWA is using
   - macOS
     ```
     sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" "awesome-pwa/.certs/meirg.co.il.test.crt"
     ```
5. Open Chrome browser and navigate to [https://meirg.co.il.test](https://meirg.co.il.test), the PWA should be served properly via HTTPS

## Set An HTTPS Connection From An Android Device To PWA

Previously, we generated `meirg.co.il.test.der.crt`, this file is the one that should be installed the Android Device.

1. Local Machine > Upload `awesome-pwa/.certs/meirg.co.il.test.der.crt` to Google Drive
2. Android Device > Download `meirg.co.il.test.der.crt` from Google Drive
3. Android Device > Settings > Search "CA Certificate" > Install anyway > Select and install `meirg.co.il.test.der.crt` from local storage
4. Android Device > Open Chrome browser and navigate to [https://meirg.co.il.test](https://meirg.co.il.test), the PWA should be served properly via HTTPS
1. From time to time, you might face an infinite loop, I'm not sure what's the cause of it, but I fix it by stopping and starting the dev server
2. I'm able to install the PWA on my Android device

**TIP**: To view the installed certificates, in the settings, search for `User certificates` 

TODO: Add images

## Controlling The Android Device With Google Chrome

1. First, [Configure your Android with Developer Options](https://developer.android.com/studio/debug/dev-options) and Allow USB Debugging. To be on the safe-side, I also downloaded and installed [Samsung Smart Switch
](https://www.samsung.com/us/support/owners/app/smart-switch) which includes Samsung Galaxy drivers. At this point I'm not sure if the drivers are necessary, I'll need to uninstall them to find out (TODO: uninstall drivers and see if it affects the installation)
1. Connect your Android device to the local machine with a USB cable
   - macOS - I used my macOS charger cable to connect since that's only cable I got with TypeC to TypeC
2. Open Chrome and navigate to Chrome's `chrome://inspect#devices` page, see [Remote debug Android devices](https://developer.chrome.com/docs/devtools/remote-debugging/)
3. (WIP) The Android device device should appear on the list, so click `inspect` to view the contents of the mobile phone, on the local machine's display. It's like using your Android device as an emulator, though stuff is happening for real.

## Conclusions

1. During the process I realized I can't use `test.meirg.co.il`, and I must use `meirg.co.il.test`, this is because I'm on macOS, I need to map all `*.test` traffic via the local DNS server (dnsmasq), and the trick is to use `/etc/resolver/test` to do that. On Linux/WSL2, or even Windows, it's way easier, you can simply change the `/etc/hosts` file and that's it.
2. Remote debugging does not work on WIFI, even though I enabled it on my Android device, so I must use a USB cable to make it work. I wonder if I'm doing something wrong.
3. I need to read/write a blog post about CA, I feel like this subject is still not 100% clear to me.
4. The application is not 100% stable in hot-reload mode and I still need to figure out why.

## Useful Resources

- https://developer.chrome.com/docs/devtools/progressive-web-apps/