This allows you to scan 18F's repos in CircleCI for repositories that have
the `forks-receive-secret-env-vars` flag set to `true`. This script will need
to be run by an GitHub owner in order to get complete results.

The API that this script uses to communicate with CircleCI is undocumented and
requires session auth. That means that you will need to get the session token
for circleci.com from your browser. To do this:

1. Got to CircleCI in Chrome, log on, and navigate to the dashboard.
2. Press `command` + `option` + `i` to open the Chrome dev tools
3. Select the `Application` tab from the list of tabs across the top of the
   screen. You may need to expand the dev tools window to see the tab.
4. In the pane on the left, got to `Storage` > `Cookies` and select
   `https://circleci.com`
5. In the pane to the right, scroll through the table until you find
   `ring-session`. Double click on the text in the `Value` column for that
   cookie and put it somewhere for later.

To run the script, do this in your terminal:

1. `cd path/to/circle-fork-env-var-config-scan`
2. `docker build -t circle-scan .`
3. `docker run -e CIRCLE_SESSION_COOKIE='<circle session cookie>' circle-scan`.
   Make sure to replace the value of `<circle session cookie>` with the value of
   the cookie from the previous steps above.
