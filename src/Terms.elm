module Terms exposing (view)

import Colors exposing (UserConfig)
import Element
import Env
import MarkdownThemed
import Route
import Ui


view : UserConfig -> Element.Element msg
view userConfig =
    Element.column
        Ui.pageContentAttributes
        [ Ui.title "Terms of service"
        , MarkdownThemed.renderFull userConfig text
        ]


text : String
text =
    """

#### Version 1.0 – June 2021

### 🤔 What is Meetdown

These legal terms are between you and meetdown.app (“we”, “our”, “us”, “Meetdown”, the software”) and you agree to them by using the Meetdown service.

You should read this document along with our [Data Privacy Notice](""" ++ Route.encode Route.PrivacyRoute ++ """).


### 💬 How to contact us

Please chat with us by emailing us at [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """)

We'll contact you in English 🇬🇧 and Emoji 😃.


### 🤝🏽 Guarantees and expectations

Meetdown makes no guarantees.

The [source code for Meetdown](https://github.com/MartinSStewart/meetdown) is open source so technical users may make their own assessment of risk.

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement.

In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

We expect all users to behave according to the [Code of conduct](""" ++ Route.encode Route.CodeOfConductRoute ++ """).


### 💵 Cost

Meetdown is a free product.


### 😔 How to make a complaint

If you have a complaint, please contact us and we'll do our best to fix the problem.

Please see "How to contact us" above.


### 📝 Making changes to this agreement

This agreement will always be available on meetdown.app.

If we make changes to it, we'll tell you once we've made them.

If you don't agree to these changes, you can close your account by pressing "Delete Account" on your profile page.

We'll destroy any data in your account, unless we need to keep it for a reason outlined in our [Privacy policy](""" ++ Route.encode Route.PrivacyRoute ++ """).


### 😭 Closing your account

To close your account, you can press the "Delete Account" button on your profile page.

We can close your account by giving you at least one weeks' notice.

We may close your account immediately if we believe you've:

- Broken the terms of this agreement
- Put us in a position where we might break the law
- Broken the law or attempted to break the law
- Given us false information at any time
- Been abusive to anyone at Meetdown or a member of our community

"""
