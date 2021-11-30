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

## PWA Available To Physical Android Device

### Setup A Local DNS Server

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
5. Restart `dnsmasq` by stopping and starting it
   ```bash
   sudo brew services stop dnsmasq
   sudo brew services start dnsmasq
   ```
1. Flush (refresh) DNS
   ```
   sudo killall -HUP mDNSResponder
   ```
2. Check your local DNS server
   ```bash
   # This is what happens when you use the default DNS server
   dig meirg.co.il.test # returns a.root-servers.net. nstld.verisign-grs.com. 2021113002 1800 900 604800 86400

   # And now via dnsmasq local DNS server
   dig meirg.co.il.test @192.168.0.5 # returns 192.168.0.5
   ```

### Control Android Device With Google Chrome

1. Android Device > First, [Configure your Android with Developer Options](https://developer.android.com/studio/debug/dev-options) and Allow USB Debugging. To be on the safe-side, I also downloaded and installed [Samsung Smart Switch
](https://www.samsung.com/us/support/owners/app/smart-switch) which includes Samsung Galaxy drivers. At this point I'm not sure if the drivers are necessary, I'll need to uninstall them to find out (TODO: uninstall drivers and see if it affects the installation)
1. Android Device > Open WIFI settings and change the DHCP settings from Auto to Manual. Set the first DNS server records to
   1. `192.168.0.5` (the local machine which is running `dnsmasq` local DNS server)
   2. `1.1.1.1` ([Cloudflare DNS](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/))
1. Android Device > Open Google Chrome and navigate to [http://meirg.co.il.test:8080](https://meirg.co.il.test:8080/#/), it **should NOT work**, as your local dev server is exposed only to the local machine. To expose it to other machines, edit [awesome-pwa/quasar.conf.js](./awesome-pwa/quasar.conf.js), change `https: false` to
    ```javascript
    devServer: {
      https: {
        allowedHosts: ['0.0.0.0/0'],
      },
      port: 8080,
      open: false // opens browser window automatically
    },
    // It's recommended to set it to false when using a custom domain
    // The default window is using `localhost` and that's not what we need
    ```
   *NOTE*: I know we're using HTTPS, while we haven't configured anything to use, bare with me
2. Android Device > Open Google Chrome and navigate to `http://meirg.co.il.test:8080`, it **should work**, as your 