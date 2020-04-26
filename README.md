# ikoa-web
**ikoa-web** is a third-party app which helps you using **iKOA** more easily. 


### Prerequisites:
1. You have google team drive(shared drive).
2. You can generate the google drive SA(service account) by yourself.


### How to deploy:
Click the button below to deploy to heroku using your own heroku account.  
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)



### Tips:
1. Be careful filling in the "herokuApp" field when deploy the app, otherwise your app can't work properly.
2. The format of "SA_JSON" field should look like the line below(delete any spaces between each JSON key, and paste it into one line):  
  {"type": "service_account","project_id": "xxxxx","private_key_id":"xxxxx",......}
3. You can ssh into the server from command line:  `heroku ps:exec -a  yourAppName` [See more details](https://devcenter.heroku.com/articles/heroku-cli)
4. You can update the iKOA version in the folder called fanza(fork the repo first, and replace the iKOA with a newer version,change the repository field,then deploy your own repo to heroku).
5. The app will be restarted automatically once every 24 hours due to heroku's policy. [See more details](https://devcenter.heroku.com/articles/dynos#restarting)
6. the format of num ID:"ABC-123" or "ABC-123,abc-124,ABC-125"(case insensitive)
7. the format of cid ID:"abc00123" or "abc00123,abc00124,abcc00125"(case insensitive)
8. If you submit many IDs one time, you can put a tag on these IDs, so they can be downloaded under the same folder.(the tag length should be no more than 10 characters, be free to use chinese or japanese name or any other language)
9. In theory, ikoa-web can upload no more than 1.5TB data to your google team drive per day.


### FAQ:
* Why does rclone failed to upload files to google team drive?  
  You need to config "TEAM_DRIVE_ID" "RCLONE_DESTINATION", "LOG_PATH", "SA_JSON_1", "SA_JSON_2" properly.
* What does "codenotenough" mean in the csv file?  
  It means you need to get a valid "SERIAL_CODE".
* Can ikoa-web bypass google drive's 750GB per day upload limit?  
  Yes, This is why you need config two SA.

## License
**ikoa-web** is released under the [MIT License](LICENSE)