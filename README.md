# ikoa-web
**ikoa-web** is a third-party app which helps you using **iKOA** more easily.

### Features:
* The docker image(186MB in total) is based on i386/alpine.
* Auto upload to google drive after download finished.
* Show the download and upload progress in web page real-time.
* Batch downloading.
* Task Queue
* Naming IDs with a tag.
* Forcing https.
* Comprehensive download statistics data(csv format).
* Customizing the admin account for logining in the web page.

### Update:
* You can choose to whether download monthly videos only(find the option in deploy page).  
* Show the waiting time if you download too fast.  
* Check whether the ID belongs to monthly video before download.  
* Choose the rclone upload strategy based on the serialCode quota.  
* Quit the download task if the serialCode quota is zero.  
* ~~Add support for iKOA version-1.5.2~~ 
* Add support for iKOA version-1.6.1  


### Prerequisites:
1. You have google team drive(shared drive).
2. You can generate the google drive SA(service account) by yourself.  
3. You have valid serialCode.


### How to deploy:
Click the button below to deploy to heroku using your own heroku account.  
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)



### Tips:
1. Be careful filling in the "herokuApp" field when deploy the app, otherwise your app can't work properly.
2. The format of "SA_JSON" field should look like the first line below(delete any spaces between each line,but don't add any **line break** between each line,then paste it into one line):  
  {"type": "service_account","project_id": "xxxxx","private_key_id":"xxxxx",......}&nbsp;&nbsp;**√**  
  {"type": "service_account",\n"project_id": "xxxxx",\n"private_key_id":"xxxxx",......}&nbsp;&nbsp;**x**
3. You can ssh into the server from command line:  `heroku ps:exec -a  yourAppName`. [See more details](https://devcenter.heroku.com/articles/heroku-cli)
4. You can update the iKOA version in the folder called fanza(fork the repo first, and replace the iKOA with a newer version,change the repository field in [app.json](app.json), then deploy your own repo to heroku).
5. The app will be restarted automatically once every 24 hours continuous running due to heroku's policy. [See more details](https://devcenter.heroku.com/articles/dynos#restarting)
6. the format of num ID:"ABC-123" or "ABC-123,abc-124,ABC-125 and more"(comma separated,case insensitive)
7. the format of cid ID:"abc00123" or "abc00123,abc00124,abc00125 and more"(comma separated,case insensitive)  
8. the format of mgs ID:"259LUXU-1200" or "259LUXU-1200,259LUXU-1201,259LUXU-1202 and more"(comma separated,case insensitive)  
9. If you submit many IDs one time, you can put a tag on these IDs, so they can be downloaded under the same folder.(the tag length should be no more than 10 characters, be free to use chinese or japanese name or any other language)
10. In theory, ikoa-web can upload no more than 1.5TB data to your google team drive per day.


### FAQ:
* Q: How can I change the config var after deployment?  
  A: You can change the config var in the settings page of the dashboard. [See more details](https://devcenter.heroku.com/articles/config-vars#managing-config-vars)
* Q: Why does rclone failed to upload files to google team drive?  
  A: First, You need to config "TEAM_DRIVE_ID" "RCLONE_DESTINATION", "LOG_PATH", "SA_JSON_1", "SA_JSON_2" properly.  
  &nbsp;&nbsp;&nbsp;&nbsp;And then check whether the two SA has been added into your team drive as a member with write permission at least(contributor or content manager).
* ~~Q: What does "codenotenough" mean in the csv file?~~    
  ~~A: It means you need to get a valid "SERIAL_CODE".~~
* Q: Can ikoa-web bypass google drive's 750GB per day upload limit?  
  A: Yes, This is why you need config two SA.
* Q: How should I do if I can't config the SA_JSON field correctly?  
  A: Check whether the one line json string matches exactly **2374** characters.
* Q: Why does the app shutdown suddenly before all tasks finished sometimes?  
  A: Please create an issue and paste the log.

## License
**ikoa-web** is released under the [MIT License](LICENSE)