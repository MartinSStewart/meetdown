module Privacy exposing (view)

import Colors exposing (UserConfig)
import Element exposing (Element)
import Env
import MarkdownThemed
import Route
import Ui


view : UserConfig -> Element msg
view userConfig =
    Element.column
        Ui.pageContentAttributes
        [ Ui.title "Privacy notice"
        , MarkdownThemed.renderFull userConfig text
        ]


text : String
text =
    """

#### Version 1.0 – June 2021

We’re committed to protecting and respecting your privacy. If you have any questions about your personal information please chat with us by emailing us at [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).


### 👀 The information we hold about you

#### - Cookie information

We use a single persistent secured httpOnly session cookie to recognise your browser and keep you logged in.

Other cookies may be introduced in the future, and if so our Privacy policy will be updated at that time.


#### - Information submitted through our service or website

- For example, when you sign up to the service and provide details such as your name and email

There may be times when you give us ‘sensitive’ information, which includes things like your racial origin, political opinions, religious beliefs, trade union membership details or biometric data. We’ll only use this information in strict accordance with the law.


### 🔍 How we use your information

To provide our services, we use it to:

- Help us manage your account
- Send you reminders for events you've joined

To meet our legal obligations, we use it to:

- Prevent illegal activities like piracy and fraud

With your permission, we use it to:

- Market and communicate our products and services where we think these will be of interest to you by email. You can always unsubscribe from receiving these if you want to by email.


### 🤝 Who we share it with

We may share your personal information with:

- Anyone who works for us when they need it to do their job.
- Anyone who you give us explicit permission to share it with.

We’ll also share it to comply with the law; to enforce our [Terms of service](""" ++ Route.encode Route.TermsOfServiceRoute ++ """) or other agreements; or to protect the rights, property or safety of us, our users or others.

### 📁 How long we keep it

We keep your data as long as you’re using Meetdown, and for 1 year after that to comply with the law. In some circumstances, like cases of fraud, we may keep data longer if we need to and/or the law says we have to.

### ✅ Your rights

You have a right to:

- Access the personal data we hold about you, or to get a copy of it.
- Make us correct inaccurate data.
- Ask us to delete, 'block' or suppress your data, though for legal reasons we might not always be able to do it.
- Object to us using your data for direct marketing and in certain circumstances ‘legitimate interests’, research and statistical reasons.
- Withdraw any consent you’ve previously given us.

To do so, please contact us by emailing [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).


### 🔒 Where we store or send your data

We might transfer and store the data we collect from you somewhere outside the European Economic Area (‘EEA’). People who work for us or our suppliers outside the EEA might also process your data.

We may share data with organisations and countries that:

- The European Commission say have adequate data protection, or
- We’ve agreed standard data protection clauses with.


### 😔 How to make a complaint

If you have a complaint, please contact us by emailing [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """) and we’ll do our best to fix the problem.


### 📝 Changes to this policy

We’ll post any changes we make to our privacy notice on this page and, if they’re significant changes we’ll let you know by email.

"""
