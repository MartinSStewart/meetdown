# Meetdown

A place to join groups of people with shared interests.

https://meetdown.app/

![image](https://user-images.githubusercontent.com/5068391/123555974-2ff4dd00-d789-11eb-8f0a-20869af7ae34.png)

### Contributing

If you want to fix something or add a feature, I recommend asking me about it on Elm slack (I am `@Martin Stewart`) or creating an issue here first.
It's much less stressful to turn down a feature _before_ you have spent time implementing it!

Also make sure to add your name to the Credits.txt if it's your first PR!

### How do I run this locally?

1. Download the Lamdera binary from here https://www.lamdera.com/start
2. Add the lamdera.exe to your path variable
3. Clone this repo
4. cd into the repo folder and run `lamdera live`

### How do I log in locally?

Easy way: Uncomment these lines in `Backend.elm`

```elm
        --_ =
        --    Debug.log "login" loginLink
```

and then click on the link that appears in the console when you try logging in.

Hard way: Create a postmark account, generate an API key, and paste it in `Env.elm` here:

```elm
postmarkServerToken =
    ""
```

(Make sure to not accidentally commit it!)

Charlon: I'm currently working on Internationalization, so if you want to help with that, please let me know!
