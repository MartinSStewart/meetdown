module UserConfig exposing (..)

import Colors exposing (fromHex)
import Date exposing (Date)
import Duration exposing (Duration)
import Element exposing (Color)
import Env
import Quantity
import Time exposing (Month(..), Weekday(..))
import TimeExtra exposing (removeTrailing0s)


type alias UserConfig =
    { theme : Theme
    , texts : Texts
    }


type alias Theme =
    { defaultText : Color
    , mutedText : Color
    , error : Color
    , submit : Color
    , link : Color
    , errorBackground : Color
    , lightGrey : Color
    , grey : Color
    , textInputHeading : Color
    , darkGrey : Color
    , invertedText : Color
    , background : Color
    , heroSvg : String
    }


darkTheme : Theme
darkTheme =
    { defaultText = fromHex "#e8ecf1"
    , mutedText = fromHex "#c7ccd3"
    , error = fromHex "#f1484e"
    , submit = fromHex "#54c0ad"
    , link = fromHex "#5aaff5"
    , errorBackground = Element.rgb 0.349 0.2745 0.2745
    , lightGrey = fromHex "#4c4d4d"
    , grey = fromHex "#6e7072"
    , textInputHeading = fromHex "#8db8ef"
    , darkGrey = fromHex "#7e858d"
    , invertedText = fromHex "#151515"
    , background = fromHex "#252525"
    , heroSvg = "/homepage-hero-dark.svg"
    }


lightTheme : Theme
lightTheme =
    { defaultText = fromHex "#022047"
    , mutedText = fromHex "#4A5E7A"
    , error = fromHex "#F8777B"
    , submit = fromHex "#55CCB6"
    , link = fromHex "#509CDB"
    , errorBackground = Element.rgb 1 0.9059 0.9059
    , lightGrey = fromHex "#f4f6f8"
    , grey = fromHex "#E0E4E8"
    , textInputHeading = fromHex "#4A5E7A"
    , darkGrey = fromHex "#AEB7C4"
    , invertedText = fromHex "#FFF"
    , background = fromHex "#FFF"
    , heroSvg = "/homepage-hero.svg"
    }


default : UserConfig
default =
    { theme = lightTheme
    , texts = englishTexts
    }


type alias Texts =
    { addEvent : String
    , addressTooLong : Int -> Int -> String
    , addressTooShort : Int -> Int -> String
    , aLoginEmailHasBeenSentTo : String
    , anAccountDeletionEmailHasBeenSentTo : String
    , andNanonymousNattendees : Int -> String
    , andOneNanonymousNattendee : String
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests : String
    , beginsIn : String
    , belowNCharactersPlease : Int -> String
    , buttonOnAGroupPage : String
    , byContinuingYouAgreeToThe : String
    , cancel : String
    , cancelChanges : String
    , cancelEvent : String
    , checkYourSpamFolderIfYouDonTSeeIt : String
    , chooseWhatTypeOfEventThisIs : String
    , codeOfConduct : String
    , codeOfConduct1 : String
    , codeOfConduct2 : String
    , codeOfConduct3 : String
    , codeOfConduct4 : String
    , codeOfConduct5 : String
    , copyPreviousEvent : String
    , createEvent : String
    , createGroup : String
    , creatingOne : String
    , creditGoesTo : String
    , dateValueMissing : String
    , daysUntilEvent : Int -> String
    , deleteAccount : String
    , deleteGroup : String
    , describeWhatYourGroupIsAboutYouCanFillOutThisLater : String
    , description : String
    , descriptionTooLong : Int -> Int -> String
    , dontBeAJerk : String
    , edit : String
    , editEvent : String
    , ended : String
    , endsIn : String
    , enterYourEmailAddress : String
    , enterYourEmailFirst : String
    , eventCantBeMoreThan : String
    , eventCanTStartInThePast : String
    , eventDescriptionOptional : String
    , eventDurationText : Bool -> String -> String -> String
    , eventName : String
    , eventOverlapsOtherEvents : String
    , eventOverlapsWithAnotherEvent : String
    , eventsCanTStartInThePast : String
    , failedToJoinEventThereArenTAnySpotsLeft : String
    , failedToJoinThisEventDoesnTExistTryRefreshingThePage : String
    , failedToLeaveEvent : String
    , faq : String
    , faq1 : String
    , faq2 : String
    , faq3 : String
    , faqQuestion1 : String
    , faqQuestion2 : String
    , faqQuestion3 : String
    , forHelpingMeOutWithPartsOfTheApp : String
    , formatDate : Date -> String
    , frequentQuestions : String
    , futureEvents : String
    , goToHomepage : String
    , group1 : String
    , groupDescription : String
    , groupName : String
    , groupNotFound : String
    , hideU_00A0Attendees : String
    , hoursLong : String
    , howManyHoursLongIsIt : String
    , howManyPeopleCanJoinLeaveThisEmptyIfThereSNoLimit : String
    , ifYouDontSeeTheEmailCheckYourSpamFolder : String
    , imageEditor : String
    , info : String
    , inPersonEvent : String
    , invalidDateFormatExpectedSomethingLike_2020_01_31 : String
    , invalidEmailAddress : String
    , invalidInput : String
    , invalidTimeFormatExpectedSomethingLike_22_59 : String
    , invalidUrlLong : String
    , invalidValueChooseAnIntegerLike5Or30OrLeaveItBlank : String
    , isItI : String
    , itsTakingPlaceAt : Bool -> String
    , iWantThisGroupToBePubliclyVisible : String
    , iWantThisGroupToBeUnlistedPeopleCanOnlyFindItIfYouLinkItToThem : String
    , joinEvent : String
    , just_1AnonymousAttendee : String
    , justNanonymousNattendees : Int -> String
    , keepItBelowNCharacters : Int -> String
    , leaveEvent : String
    , linkThatWillBeShownWhenTheEventStartsOptional : String
    , loading : String
    , login : String
    , logout : String
    , makeGroupPublic : String
    , makeGroupUnlisted : String
    , meetingAddressOptional : String
    , moderationHelpRequest : String
    , myGroups : String
    , nameMustBeAtLeast : Int -> String
    , nameMustBeAtMost : Int -> String
    , newEvent : String
    , newGroup : String
    , nextEventIsIn : String
    , noGroupsYet : String
    , noNewEventsHaveBeenPlannedYet : String
    , noOneAttended : String
    , noOnePlansOnAttending : String
    , notifyMeOfNewEvents : String
    , numberOfHours : String -> String
    , numberOfMinutes : String -> String
    , onePersonAttended : String
    , onePersonAttendedItWasYou : String
    , onePersonIsAttending : String
    , onePersonIsAttendingItSYou : String
    , onePersonPlansOnAttending : String
    , onePersonPlansOnAttendingItSYou : String
    , ongoingEvent : String
    , onlineAndInPersonEvent : String
    , onlineEvent : String
    , oopsSomethingWentWrongRenderingThisPage : String
    , or : String
    , organizer : String
    , pastEvents : String
    , peoplePlanOnAttending : Int -> Bool -> String
    , peopleAreAttending : Int -> Bool -> String
    , peopleAttended : Int -> Bool -> String
    , pickAVisibilitySetting : String
    , pressTheLinkInItToConfirmDeletingYourAccount : String
    , privacy : String
    , privacyMarkdown : String -> String
    , privacyNotice : String
    , profile : String
    , readMore : String
    , recancelEvent : String
    , reset : String
    , save : String
    , saveChanges : String
    , saving : String
    , search : String
    , searchForGroups : String
    , subscribingToOne : String
    , searchResultsFor : String
    , showAll : String
    , showFirst : String
    , showAttendees : String
    , signInAndWeWillGetYouSignedUpForThatEvent : String
    , signInAndWeWillGetYouSignedUpForThe : String -> String
    , sinceThisIsYourFirstGroupWeRecommendYouReadThe : String
    , sorryThatGroupNameIsAlreadyBeingUsed : String
    , stopNotifyingMeOfNewEvents : String
    , submit : String
    , subscribedGroups : String
    , terms : String
    , theEventCanTStartInThePast : String
    , theEventIsTakingPlaceNowAt : String
    , theEventWillTakePlaceAt : String
    , theLinkYouUsedIsEitherInvalidOrHasExpired : String
    , theMostImportantRuleIs : String
    , theStartTimeCanTBeChangedSinceTheEventHasAlreadyStarted : String
    , thisEventDoesNotExist : String
    , thisEventSomehowDoesNotExistTryRefreshingThePage : String
    , thisEventWasCancelled : String
    , thisEventWillBeInPerson : String
    , thisEventWillBeOnline : String
    , thisEventWillBeOnlineAndInPerson : String
    , thisGroupHasTooManyEvents : String
    , thisGroupWasCreatedOn : String
    , timeDiffToString : Time.Posix -> Time.Posix -> String
    , timeValueMissing : String
    , title : String
    , tos : String
    , tosMarkdown : String -> String -> String
    , twoPeopleOnAVideoConference : String
    , uncancelEvent : String
    , uploadImage : String
    , userNotFound : String
    , valueMustBeGreaterThan0 : String
    , weDontSellYourDataWeDontShowAdsAndItsFree : String
    , welcomePage : String
    , whatDoYouWantPeopleToKnowAboutYou : String
    , whatSTheNameOfYourGroup : String
    , whenDoesItStart : String
    , youCanDoThatHere : String
    , youCanTEditEventsThatHaveAlreadyHappened : String
    , youCanTEditTheStartTimeOfAnEventThatIsOngoing : String
    , youHavenTCreatedAnyGroupsYet : String
    , youNeedToAllowAtLeast2PeopleToJoinTheEvent : String
    , yourEmailAddress : String
    , yourName : String
    , yourNameCantBeEmpty : String
    }


englishTexts : Texts
englishTexts =
    { addEvent = "Add event"
    , addressTooLong = \length maxLength -> "Address is " ++ String.fromInt length ++ " characters long. Keep it under " ++ String.fromInt maxLength ++ "."
    , addressTooShort = \length minLength -> "Address is " ++ String.fromInt length ++ " characters long. It needs to be at least " ++ String.fromInt minLength ++ "."
    , aLoginEmailHasBeenSentTo = "A login email has been sent to "
    , anAccountDeletionEmailHasBeenSentTo = "An account deletion email has been sent to "
    , andNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "And one\nanonymous\nattendee"

            else
                "And " ++ String.fromInt attendeeCount ++ "\nanonymous\nattendees"
    , andOneNanonymousNattendee = "And one\nanonymous\nattendee"
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests = "A place to join groups of people with shared interests"
    , beginsIn = "Begins in "
    , belowNCharactersPlease = \n -> "Below " ++ String.fromInt n ++ " characters please"
    , buttonOnAGroupPage = "\" button on a group page."
    , byContinuingYouAgreeToThe = "By continuing, you agree to the "
    , cancel = "Cancel"
    , cancelChanges = "Cancel changes"
    , cancelEvent = "Cancel event"
    , checkYourSpamFolderIfYouDonTSeeIt = "Check your spam folder if you don't see it."
    , chooseWhatTypeOfEventThisIs = "Choose what type of event this is"
    , codeOfConduct = "Code of Conduct"
    , codeOfConduct1 = "Here is some guidance in order to fulfill the \"don't be a jerk\" rule:"
    , codeOfConduct2 = "• Respect people regardless of their race, gender, sexual identity, nationality, appearance, or related characteristics."
    , codeOfConduct3 = "• Be respectful to the group organizers. They put in the time to coordinate an event and they are willing to invite strangers. Don't betray their trust in you!"
    , codeOfConduct4 = "• To group organizers: Make people feel included. It's hard for people to participate if they feel like an outsider."
    , codeOfConduct5 = "• If someone is being a jerk that is not an excuse to be a jerk back. Ask them to stop, and if that doesn't work, avoid them and explain the problem here "
    , copyPreviousEvent = "Copy previous event"
    , createEvent = "Create event"
    , createGroup = "Create group"
    , creatingOne = "creating one"
    , creditGoesTo = ". Credit goes to "
    , dateValueMissing = "Date value missing"
    , daysUntilEvent = \days -> "Days until event: " ++ String.fromInt days
    , deleteAccount = "Delete account"
    , deleteGroup = "Delete group"
    , describeWhatYourGroupIsAboutYouCanFillOutThisLater = "Describe what your group is about (you can fill out this later)"
    , description = "Description"
    , descriptionTooLong = \descriptionLength maxLength -> "Description is " ++ String.fromInt descriptionLength ++ " characters long. Keep it under " ++ String.fromInt maxLength ++ "."
    , dontBeAJerk = "don't be a jerk"
    , edit = "Edit"
    , editEvent = "Edit event"
    , ended = "Ended "
    , endsIn = "Ends in "
    , enterYourEmailAddress = "Enter your email address"
    , enterYourEmailFirst = "Enter your email first"
    , eventCantBeMoreThan = "The event can't be more than "
    , eventCanTStartInThePast = "Event can't start in the past"
    , eventDescriptionOptional = "Event description (optional)"
    , eventDurationText =
        \isPastEvent durationText eventTypeText ->
            if isPastEvent then
                "• This was a " ++ durationText ++ " long " ++ eventTypeText

            else
                "• This is a " ++ durationText ++ " long " ++ eventTypeText
    , eventName = "Event name"
    , eventOverlapsOtherEvents = "Event overlaps other events"
    , eventOverlapsWithAnotherEvent = "Event overlaps with another event"
    , eventsCanTStartInThePast = "Events can't start in the past"
    , failedToJoinEventThereArenTAnySpotsLeft = "Failed to join event, there aren't any spots left."
    , failedToJoinThisEventDoesnTExistTryRefreshingThePage = "Failed to join, this event doesn't exist (try refreshing the page?)"
    , failedToLeaveEvent = "Failed to leave event"
    , faq = "FaQ"
    , faq1 = "I dislike that meetup.com charges money, spams me with emails, and feels bloated. Also I wanted to try making something more substantial using "
    , faq2 = " to see if it's feasible to use at work."
    , faq3 = "I just spend my own money to host it. That's okay because it's designed to cost very little to run. In the unlikely event that Meetdown gets very popular and hosting costs become too expensive, I'll ask for donations."
    , faqQuestion1 = "Who is behind all this?"
    , faqQuestion2 = "Why was this website made?"
    , faqQuestion3 = "If this website is free and doesn't run ads or sell data, how does it sustain itself?"
    , forHelpingMeOutWithPartsOfTheApp = " for helping me out with parts of the app."
    , formatDate = Date.format "MMMM ddd"
    , frequentQuestions = "Frequently asked questions"
    , futureEvents = "Future events"
    , goToHomepage = "Go to homepage"
    , group1 = "You haven't subscribed to any groups. You can do that by pressing the \""
    , groupDescription = "Group description"
    , groupName = "Group name"
    , groupNotFound = "Group not found"
    , hideU_00A0Attendees = "(Hide\u{00A0}attendees)"
    , hoursLong = " hours long."
    , howManyHoursLongIsIt = "How many hours long is it?"
    , howManyPeopleCanJoinLeaveThisEmptyIfThereSNoLimit = "How many people can join (leave this empty if there's no limit)"
    , ifYouDontSeeTheEmailCheckYourSpamFolder = "If you don't see the email, check your spam folder."
    , imageEditor = "Image editor"
    , info = "Info"
    , inPersonEvent = "in-person event 🤝"
    , invalidDateFormatExpectedSomethingLike_2020_01_31 = "Invalid date format. Expected something like 2020-01-31"
    , invalidEmailAddress = "Invalid email address"
    , invalidInput = "Invalid input. Write something like 1 or 2.5"
    , invalidTimeFormatExpectedSomethingLike_22_59 = "Invalid time format. Expected something like 22:59"
    , invalidUrlLong = "Invalid url. Enter something like https://my-hangouts.com or leave it blank"
    , invalidValueChooseAnIntegerLike5Or30OrLeaveItBlank = "Invalid value. Choose an integer like 5 or 30, or leave it blank."
    , isItI = "It is I, "
    , itsTakingPlaceAt =
        \isPastEvent ->
            if isPastEvent then
                "• It took place at "

            else
                "• It's taking place at "
    , iWantThisGroupToBePubliclyVisible = "I want this group to be publicly visible"
    , iWantThisGroupToBeUnlistedPeopleCanOnlyFindItIfYouLinkItToThem = "I want this group to be unlisted (people can only find it if you link it to them)"
    , joinEvent = "Join event"
    , just_1AnonymousAttendee = "• Just 1 anonymous attendee"
    , justNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "• Just one anonymous attendee"

            else
                "• Just " ++ String.fromInt attendeeCount ++ " anonymous attendees"
    , keepItBelowNCharacters = \n -> "Keep it below " ++ String.fromInt n ++ " characters"
    , leaveEvent = "Leave event"
    , linkThatWillBeShownWhenTheEventStartsOptional = "Link that will be shown when the event starts (optional)"
    , loading = "Loading"
    , login = "Sign up / Login"
    , logout = "Logout"
    , makeGroupPublic = "Make group public"
    , makeGroupUnlisted = "Make group unlisted"
    , meetingAddressOptional = "Meeting address (optional)"
    , moderationHelpRequest = "Moderation help request"
    , myGroups = "My groups"
    , nameMustBeAtLeast = \number -> "Name must be at least " ++ String.fromInt number ++ " characters long."
    , nameMustBeAtMost = \number -> "Name is too long. Keep it under " ++ String.fromInt number ++ " characters."
    , newEvent = "New event"
    , newGroup = "New group"
    , nextEventIsIn = "Next event is in "
    , noGroupsYet = "You don't have any groups. Get started by "
    , noNewEventsHaveBeenPlannedYet = "No new events have been planned yet."
    , noOneAttended = "• No one attended 💔"
    , noOnePlansOnAttending = "• No one plans on attending"
    , notifyMeOfNewEvents = "Notify me of new events"
    , numberOfHours =
        \nbHours ->
            if nbHours == "1" then
                "1\u{00A0}hour"

            else
                nbHours ++ "\u{00A0}hours"
    , numberOfMinutes =
        \nbMinutes ->
            if nbMinutes == "1" then
                "1\u{00A0}minute"

            else
                nbMinutes ++ "\u{00A0}minutes"
    , onePersonAttended = "• One person attended"
    , onePersonAttendedItWasYou = "• One person attended (it was you)"
    , onePersonIsAttending = "• One person is attending"
    , onePersonIsAttendingItSYou = "• One person is attending (it's you)"
    , onePersonPlansOnAttending = "• One person plans on attending"
    , onePersonPlansOnAttendingItSYou = "• One person plans on attending (it's you)"
    , ongoingEvent = "Ongoing event"
    , onlineAndInPersonEvent = "online and in-person event 🤝💻"
    , onlineEvent = "online event 💻"
    , oopsSomethingWentWrongRenderingThisPage = "Oops! Something went wrong rendering this page: "
    , or = " or "
    , organizer = "Organizer"
    , pastEvents = "Past events"
    , peoplePlanOnAttending =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " people plan on attending"
                ++ (if isAttending then
                        " (including you)"

                    else
                        ""
                   )
    , peopleAreAttending =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " people are attending"
                ++ (if isAttending then
                        " (including you)"

                    else
                        ""
                   )
    , peopleAttended =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " people attended"
                ++ (if isAttending then
                        " (including you)"

                    else
                        ""
                   )
    , pickAVisibilitySetting = "Pick a visibility setting"
    , pressTheLinkInItToConfirmDeletingYourAccount = ". Press the link in it to confirm deleting your account."
    , privacy = "Privacy"
    , privacyMarkdown =
        \termsOfServiceRoute ->
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

We’ll also share it to comply with the law; to enforce our [Terms of service](""" ++ termsOfServiceRoute ++ """) or other agreements; or to protect the rights, property or safety of us, our users or others.

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
    , privacyNotice = "Privacy notice"
    , profile = "Profile"
    , readMore = "Read more"
    , recancelEvent = "Recancel event"
    , reset = "Reset"
    , save = "Save"
    , saveChanges = "Save changes"
    , saving = "Saving..."
    , search = "Search"
    , searchForGroups = "Search for groups"
    , subscribingToOne = "subscribing to one."
    , searchResultsFor = "Search results for "
    , showAll = "Show all"
    , showFirst = "Show first"
    , showAttendees = "(Show\u{00A0}attendees)"
    , signInAndWeWillGetYouSignedUpForThatEvent = "Sign in and we'll get you signed up for that event"
    , signInAndWeWillGetYouSignedUpForThe = \eventName -> "Sign in and we'll get you signed up for the " ++ eventName ++ " event."
    , sinceThisIsYourFirstGroupWeRecommendYouReadThe = "Since this is your first group, we recommend you read the "
    , sorryThatGroupNameIsAlreadyBeingUsed = "Sorry, that group name is already being used."
    , stopNotifyingMeOfNewEvents = "Stop notifying me of new events"
    , submit = "Submit"
    , subscribedGroups = "Subscribed groups"
    , terms = "Terms"
    , theEventCanTStartInThePast = "The event can't start in the past"
    , theEventIsTakingPlaceNowAt = "• The event is taking place now at "
    , theEventWillTakePlaceAt = "• The event will take place at "
    , theLinkYouUsedIsEitherInvalidOrHasExpired = "The link you used is either invalid or has expired."
    , theMostImportantRuleIs = "The most important rule is"
    , theStartTimeCanTBeChangedSinceTheEventHasAlreadyStarted = "The start time can't be changed since the event has already started."
    , thisEventDoesNotExist = "This event doesn't exist."
    , thisEventSomehowDoesNotExistTryRefreshingThePage = "This event somehow doesn't exist. Try refreshing the page?"
    , thisEventWasCancelled = "This event was cancelled "
    , thisEventWillBeInPerson = "This event will be in person"
    , thisEventWillBeOnline = "This event will be online"
    , thisEventWillBeOnlineAndInPerson = "This event will be online and in person"
    , thisGroupHasTooManyEvents = "This group has too many events"
    , thisGroupWasCreatedOn = "This group was created on "
    , timeDiffToString = diffToStringEnglish
    , timeValueMissing = "Time value missing"
    , title = "Event"
    , tos = "Terms of Service"
    , tosMarkdown = \privacyRoute codeOfConductRoute -> """

#### Version 1.0 – June 2021

### 🤔 What is Meetdown

These legal terms are between you and meetdown.app (“we”, “our”, “us”, “Meetdown”, the software”) and you agree to them by using the Meetdown service.

You should read this document along with our [Data Privacy Notice](""" ++ privacyRoute ++ """).


### 💬 How to contact us

Please chat with us by emailing us at [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """)

We'll contact you in English 🇬🇧 and Emoji 😃.


### 🤝🏽 Guarantees and expectations

Meetdown makes no guarantees.

The [source code for Meetdown](https://github.com/MartinSStewart/meetdown) is open source so technical users may make their own assessment of risk.

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement.

In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

We expect all users to behave according to the [Code of conduct](""" ++ codeOfConductRoute ++ """).


### 💵 Cost

Meetdown is a free product.


### 😔 How to make a complaint

If you have a complaint, please contact us and we'll do our best to fix the problem.

Please see "How to contact us" above.


### 📝 Making changes to this agreement

This agreement will always be available on meetdown.app.

If we make changes to it, we'll tell you once we've made them.

If you don't agree to these changes, you can close your account by pressing "Delete Account" on your profile page.

We'll destroy any data in your account, unless we need to keep it for a reason outlined in our [Privacy policy](""" ++ privacyRoute ++ """).


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
    , twoPeopleOnAVideoConference = "Two people on a video conference"
    , uncancelEvent = "Uncancel event"
    , uploadImage = "Upload image"
    , userNotFound = "User not found"
    , valueMustBeGreaterThan0 = "Value must be greater than 0."
    , weDontSellYourDataWeDontShowAdsAndItsFree = "We don't sell your data, we don't show ads, and it's free."
    , welcomePage = "Welcome to the event!"
    , whatDoYouWantPeopleToKnowAboutYou = "What do you want people to know about you?"
    , whatSTheNameOfYourGroup = "What's the name of your group?"
    , whenDoesItStart = "When does it start?"
    , youCanDoThatHere = "You can do that here."
    , youCanTEditEventsThatHaveAlreadyHappened = "You can't edit events that have already happened"
    , youCanTEditTheStartTimeOfAnEventThatIsOngoing = "You can't edit the start time of an event that is ongoing"
    , youHavenTCreatedAnyGroupsYet = "You haven't created any groups yet. "
    , youNeedToAllowAtLeast2PeopleToJoinTheEvent = "You need to allow at least 2 people to join the event."
    , yourEmailAddress = "Your email address"
    , yourName = "Your name"
    , yourNameCantBeEmpty = "Your name can't be empty"
    }


frenchTexts : Texts
frenchTexts =
    { addEvent = "Ajouter ton événement"
    , addressTooLong = \length maxLength -> "Ton adresse fait " ++ String.fromInt length ++ " caractères. Essaye de rester en dessous de " ++ String.fromInt maxLength ++ "."
    , addressTooShort = \length minLength -> "Ton adresse fait " ++ String.fromInt length ++ " caractères. Il en faut au moins " ++ String.fromInt minLength ++ "."
    , aLoginEmailHasBeenSentTo = "Un email de connexion vient d'être envoyé à "
    , anAccountDeletionEmailHasBeenSentTo = "Un email pour supprimer ton compte vient d'être envoyé à "
    , andNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "et un.e participant.e anonyme"

            else
                "et " ++ String.fromInt attendeeCount ++ " participant.es anonymes"
    , andOneNanonymousNattendee = "Et un.e\nparticipant.e\nanonyme"
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests = "Un endroit où rejoindre des groupes de personnes qui partagent tes centres d'intérêt"
    , beginsIn = "Début dans "
    , belowNCharactersPlease = \n -> "Moins de " ++ String.fromInt n ++ " caractères, s'il te plaît"
    , buttonOnAGroupPage = "\" sur la page d'un groupe."
    , byContinuingYouAgreeToThe = "En continuant, tu acceptes les "
    , cancel = "Annuler"
    , cancelChanges = "Annuler les changements"
    , cancelEvent = "Annuler l'événement"
    , checkYourSpamFolderIfYouDonTSeeIt = "Vérifie ton dossier spam si tu ne le vois pas."
    , chooseWhatTypeOfEventThisIs = "Choisis le type d'événement"
    , codeOfConduct = "Code de conduite"
    , codeOfConduct1 = "Voici quelques conseils pour respecter la règle \"ne sois pas un.e imbécile\":"
    , codeOfConduct2 = "• Respecte les gens, peu importe leur race, leur genre, leur identité sexuelle, leur nationalité, leur apparence ou toute autre caractéristique."
    , codeOfConduct3 = "• Sois respectueux envers les organisateurs de groupes. Ils consacrent du temps à coordonner un événement et ils sont prêts à inviter des gens qu'ils ne connaissent pas. Ne trahis pas leur confiance en toi !"
    , codeOfConduct4 = "• Pour les organisateurs de groupes: Faites en sorte que les gens se sentent inclus. Il est difficile pour les gens de participer s'ils se sentent comme des étrangers."
    , codeOfConduct5 = "• Si quelqu'un.e est un.e imbécile, ce n'est pas une excuse pour l'être aussi. Dis-leur d'arrêter et si ça ne marche pas, évite-les et explique le problème ici "
    , copyPreviousEvent = "Copier l'événement précédent"
    , createEvent = "Créer ton événement"
    , createGroup = "Créer un groupe"
    , creatingOne = "en créer un"
    , creditGoesTo = ". Un grand merci à "
    , dateValueMissing = "Date manquante"
    , daysUntilEvent = \days -> "Jours jusqu'à l'événement : " ++ String.fromInt days
    , deleteAccount = "Supprimer mon compte"
    , deleteGroup = "Supprimer le groupe"
    , describeWhatYourGroupIsAboutYouCanFillOutThisLater = "Décris l'objet de ton groupe (tu peux remplir cette partie plus tard)."
    , description = "Description"
    , descriptionTooLong = \descriptionLength maxLength -> "La description fait " ++ String.fromInt descriptionLength ++ " caractères. Limite-la à " ++ String.fromInt maxLength ++ "."
    , dontBeAJerk = "ne sois pas un.e imbécile"
    , edit = "Modifier"
    , editEvent = "Modifier l'événement"
    , ended = "Terminé il y a "
    , endsIn = "Se termine dans "
    , enterYourEmailAddress = "Entre ton adresse email"
    , enterYourEmailFirst = "Entre ton email d'abord"
    , eventCantBeMoreThan = "L'événement ne peut pas durer plus de "
    , eventCanTStartInThePast = "L'événement ne peut pas commencer dans le passé"
    , eventDescriptionOptional = "Description de l'événement (optionnel)"
    , eventDurationText =
        \isPastEvent durationText eventTypeText ->
            if isPastEvent then
                "• C'était un " ++ eventTypeText ++ " de " ++ durationText

            else
                "• C'est un " ++ eventTypeText ++ " de " ++ durationText
    , eventName = "Nom de l'événement"
    , eventOverlapsOtherEvents = "L'événement a lieu en même temps que d'autres événements"
    , eventOverlapsWithAnotherEvent = "L'événement a lieu en même temps qu'un autre événement"
    , eventsCanTStartInThePast = "Les événements ne peuvent pas commencer dans le passé"
    , failedToJoinEventThereArenTAnySpotsLeft = "Impossible de rejoindre l'événement, il n'y a plus de place."
    , failedToJoinThisEventDoesnTExistTryRefreshingThePage = "Impossible de rejoindre, cet événement n'existe pas (essaie de rafraîchir la page ?)"
    , failedToLeaveEvent = "Impossible de quitter l'événement"
    , faq = "Questions fréquentes"
    , faq1 = "Je n'aime pas que meetup.com soit payant, m'envoie des emails de spam et soit trop lourd. J'ai aussi voulu essayer de faire quelque chose de plus substantiel en utilisant "
    , faq2 = " pour voir si c'était faisable de l'utiliser au travail."
    , faq3 = "Je dépense mon propre argent pour l'héberger. C'est ok car il est conçu pour coûter très peu à faire tourner. Dans le cas improbable où Meetdown deviendrait très populaire et que les coûts d'hébergement deviennent trop élevés, je demanderai des dons."
    , faqQuestion1 = "Qui est derrière tout ça ?"
    , faqQuestion2 = "Pourquoi avoir créé ce site web ?"
    , faqQuestion3 = "Si ce site web est gratuit et ne vend pas tes données, comment est-il financé ?"
    , forHelpingMeOutWithPartsOfTheApp = " pour m'avoir aidé avec certaines parties de l'appli."
    , formatDate =
        let
            monthToName : Date.Month -> String
            monthToName m =
                case m of
                    Jan ->
                        "janvier"

                    Feb ->
                        "février"

                    Mar ->
                        "mars"

                    Apr ->
                        "avril"

                    May ->
                        "mai"

                    Jun ->
                        "juin"

                    Jul ->
                        "juillet"

                    Aug ->
                        "août"

                    Sep ->
                        "septembre"

                    Oct ->
                        "octobre"

                    Nov ->
                        "novembre"

                    Dec ->
                        "décembre"

            weekdayToName : Weekday -> String
            weekdayToName wd =
                case wd of
                    Mon ->
                        "lundi"

                    Tue ->
                        "mardi"

                    Wed ->
                        "mercredi"

                    Thu ->
                        "jeudi"

                    Fri ->
                        "vendredi"

                    Sat ->
                        "samedi"

                    Sun ->
                        "dimanche"

            withOrdinalSuffix : Int -> String
            withOrdinalSuffix n =
                case n of
                    1 ->
                        "1er"

                    _ ->
                        String.fromInt n

            dateLanguageFr : Date.Language
            dateLanguageFr =
                { monthName = monthToName
                , monthNameShort = monthToName >> String.left 3
                , weekdayName = weekdayToName
                , weekdayNameShort = weekdayToName >> String.left 3
                , dayWithSuffix = withOrdinalSuffix
                }
        in
        Date.formatWithLanguage dateLanguageFr "ddd MMMM"
    , frequentQuestions = "Questions fréquentes"
    , futureEvents = "Événements à venir"
    , goToHomepage = "Aller à l'accueil"
    , group1 = "Tu n'es abonné à aucun groupe. Tu peux le faire en appuyant sur le bouton \""
    , groupDescription = "Description du groupe"
    , groupName = "Nom du groupe"
    , groupNotFound = "Groupe introuvable"
    , hideU_00A0Attendees = "(Masquer\u{00A0}les participants)"
    , hoursLong = " heures."
    , howManyHoursLongIsIt = "Combien d'heures dure-t-il ?"
    , howManyPeopleCanJoinLeaveThisEmptyIfThereSNoLimit = "Combien de personnes peuvent rejoindre (laisse vide s'il n'y a pas de limite)"
    , ifYouDontSeeTheEmailCheckYourSpamFolder = "Si tu ne vois pas l'email, vérifie ton dossier spam."
    , imageEditor = "Éditeur d'image"
    , info = "Infos"
    , inPersonEvent = "événement en personne 🤝"
    , invalidDateFormatExpectedSomethingLike_2020_01_31 = "Format de date invalide. Attendu quelque chose comme 2020-01-31"
    , invalidEmailAddress = "Adresse email invalide"
    , invalidInput = "Entrée invalide. Écris quelque chose comme 1 ou 2.5"
    , invalidTimeFormatExpectedSomethingLike_22_59 = "Format d'heure invalide. Attendu quelque chose comme 22:59"
    , invalidUrlLong = "URL invalide. Entre quelque chose comme https://my-hangout.com ou laisse-le vide"
    , invalidValueChooseAnIntegerLike5Or30OrLeaveItBlank = "Valeur invalide. Choisis un entier comme 5 ou 30, ou laisse-le vide."
    , isItI = "C'est moi, "
    , itsTakingPlaceAt =
        \isPastEvent ->
            if isPastEvent then
                "• C'était à "

            else
                "• C'est à "
    , iWantThisGroupToBePubliclyVisible = "Je veux que ce groupe soit visible publiquement"
    , iWantThisGroupToBeUnlistedPeopleCanOnlyFindItIfYouLinkItToThem = "Je veux que ce groupe soit non listé (les gens ne peuvent le trouver que si tu leur donnes le lien)"
    , joinEvent = "Rejoindre l'événement"
    , just_1AnonymousAttendee = "• Juste 1 participant anonyme"
    , justNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "Un participant anonyme"

            else
                String.fromInt attendeeCount ++ " participants anonymes"
    , keepItBelowNCharacters = \n -> "Reste en dessous de " ++ String.fromInt n ++ " caractères"
    , leaveEvent = "Quitter l'événement"
    , linkThatWillBeShownWhenTheEventStartsOptional = "Lien qui sera affiché lorsque l'événement commencera (optionnel)"
    , loading = "Chargement"
    , login = "S'inscrire / Se connecter"
    , logout = "Déconnexion"
    , makeGroupPublic = "Rendre le groupe public"
    , makeGroupUnlisted = "Rendre le groupe non listé"
    , meetingAddressOptional = "Adresse de rencontre (optionnel)"
    , moderationHelpRequest = "Demande d'aide pour la modération"
    , myGroups = "Mes groupes"
    , nameMustBeAtLeast = \minLength -> "Le nom doit contenir au moins " ++ String.fromInt minLength ++ " caractères."
    , nameMustBeAtMost = \maxLength -> "Le nom doit contenir au plus " ++ String.fromInt maxLength ++ " caractères."
    , newEvent = "Nouvel événement"
    , newGroup = "Nouveau groupe"
    , nextEventIsIn = "Le prochain événement est dans "
    , noGroupsYet = "Tu n'as pas encore de groupes. Commence par "
    , noNewEventsHaveBeenPlannedYet = "Aucun nouvel événement n'a été planifié pour le moment."
    , noOneAttended = "• Personne n'y est allé 💔"
    , noOnePlansOnAttending = "• Personne ne compte y assister"
    , notifyMeOfNewEvents = "Me notifier des nouveaux événements"
    , numberOfHours =
        \nbHours ->
            if nbHours == "1" then
                "1\u{00A0}heure"

            else
                nbHours ++ "\u{00A0}heures"
    , numberOfMinutes =
        \nbMinutes ->
            if nbMinutes == "1" then
                "1\u{00A0}minute"

            else
                nbMinutes ++ "\u{00A0}minutes"
    , onePersonAttended = "• Une personne y est allée"
    , onePersonAttendedItWasYou = "• Une personne y est allée (c'était toi)"
    , onePersonIsAttending = "• Une personne va y assister"
    , onePersonIsAttendingItSYou = "• Une personne va y assister (c'est toi)"
    , onePersonPlansOnAttending = "• Une personne prévoit d'y assister"
    , onePersonPlansOnAttendingItSYou = "• Une personne prévoit d'y assister (c'est toi)"
    , ongoingEvent = "Événement en cours"
    , onlineAndInPersonEvent = "événement en ligne et en personne 🤝💻"
    , onlineEvent = "événement en ligne 💻"
    , oopsSomethingWentWrongRenderingThisPage = "Oups, quelque chose s'est mal passé lors du rendu de cette page."
    , or = " ou "
    , organizer = "Organisateur"
    , pastEvents = "Événements passés"
    , peoplePlanOnAttending =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " personnes prévoient de participer"
                ++ (if isAttending then
                        " (toi y compris)"

                    else
                        ""
                   )
    , peopleAreAttending =
        \attendeeCount isAttending ->
            if isAttending then
                "• Toi et " ++ String.fromInt (attendeeCount - 1) ++ " autres personnes participez"

            else
                "• " ++ String.fromInt attendeeCount ++ " personnes participent"
    , peopleAttended =
        \attendeeCount isAttending ->
            if isAttending then
                "• Toi et " ++ String.fromInt (attendeeCount - 1) ++ " autres personnes avez participé"

            else
                "• " ++ String.fromInt attendeeCount ++ " personnes ont participé"
    , pickAVisibilitySetting = "Choisis un paramètre de visibilité"
    , pressTheLinkInItToConfirmDeletingYourAccount = "Clique sur le lien pour confirmer la suppression de ton compte."
    , privacy = "Confidentialité"
    , privacyMarkdown =
        \termsOfServiceRoute ->
            """
#### Version 1.0 – Juin 2021

Nous nous engageons à protéger et à respecter ta vie privée. Si tu as des questions sur tes informations personnelles, n'hésite pas à nous contacter par e-mail à [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).

### 👀 Les informations que nous détenons sur toi

#### - Informations sur les cookies

Nous utilisons un seul cookie de session persistant sécurisé httpOnly pour reconnaître ton navigateur et te garder connecté.

D'autres cookies peuvent être introduits à l'avenir, et si c'est le cas, notre politique de confidentialité sera mise à jour à ce moment-là.

#### - Informations soumises à travers notre service ou notre site web

- Par exemple, lorsque tu t'inscris au service et fournis des détails tels que ton nom et ton adresse e-mail.

Il peut arriver que tu nous donnes des informations «sensibles», qui comprennent des choses comme ton origine raciale, tes opinions politiques, tes croyances religieuses, tes détails d'adhésion à un syndicat ou tes données biométriques. Nous n'utiliserons ces informations que dans le strict respect de la loi.

### 🔍 Comment nous utilisons tes informations

Pour fournir nos services, nous les utilisons pour:

- T'aider à gérer ton compte
- T'envoyer des rappels pour les événements auxquels tu as participé

Pour répondre à nos obligations légales, nous les utilisons pour:

- Prévenir les activités illégales telles que la piraterie et la fraude

Avec ta permission, nous les utilisons pour:

- Faire la promotion et communiquer nos produits et services où nous pensons que cela t'intéressera par e-mail. Tu peux toujours te désabonner de la réception de ces e-mails si tu le souhaites.

### 🤝 Avec qui nous partageons tes informations

Nous pouvons partager tes informations personnelles avec:

- Toute personne qui travaille pour nous lorsque elle en a besoin pour faire son travail.
- Toute personne à laquelle tu nous donnes une autorisation explicite de partager tes informations.

Nous partagerons également tes informations pour nous conformer à la loi; pour faire respecter nos [Conditions d'utilisation](""" ++ termsOfServiceRoute ++ """) ou d'autres accords; ou pour protéger les droits, la propriété ou la sécurité de nous, de nos utilisateurs ou d'autres.

### 📁 Combien de temps nous les conservons

Nous conservons tes données aussi longtemps que tu utilises Meetdown, et pendant 1 an après cela pour nous conformer à la loi. Dans certains cas, comme les cas de fraude, nous pouvons conserver les données plus longtemps si nous en avons besoin et / ou que la loi nous y oblige.

### ✅ Tes droits

Tu as le droit de:

- Accéder aux données personnelles que nous détenons sur toi, ou d'en obtenir une copie.
- Nous demander de corriger des données inexactes.
- Nous demander de supprimer, de bloquer ou de supprimer tes données, bien que pour des raisons légales, nous ne puissions pas toujours le faire.
- T'opposer à l'utilisation de tes données à des fins de marketing direct et dans certaines circonstances, à des fins de recherche et de statistiques.
- Retirer ton consentement que nous t'avons précédemment donné

Pour ce faire, contacte nous par e-mail à [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).

### 🔒 Où nous stockons ou envoyons tes données

Nous pouvons transférer et stocker les données que nous collectons quelque part en dehors de l'Union européenne («UE»). Les personnes qui travaillent pour nous ou nos fournisseurs en dehors de l'UE peuvent également traiter tes données.

Nous pouvons partager tes données avec des organisations et des pays qui:

- La Commission européenne dit avoir une protection des données adéquate, ou
- Nous avons conclu des clauses-types de protection des données avec.


### 😔 Comment faire une réclamation

Si tu as une réclamation, n'hésite pas à nous contacter par e-mail à [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """) et nous ferons de notre mieux pour résoudre le problème.

### 📝 Modifications de cette politique

Nous publierons toute modification que nous apportons à notre avis de confidentialité sur cette page et, si elles sont des modifications importantes, nous te préviendrons par e-mail.

"""
    , privacyNotice = "Notice de confidentialité"
    , profile = "Profil"
    , readMore = "En savoir plus"
    , recancelEvent = "Réannuler l'événement"
    , reset = "Réinitialiser"
    , save = "Enregistrer"
    , saveChanges = "Enregistrer les modifications"
    , saving = "Enregistrement en cours..."
    , search = "Rechercher"
    , searchForGroups = "Rechercher des groupes"
    , subscribingToOne = "rejoindre un groupe."
    , searchResultsFor = "Résultats de recherche pour "
    , showAll = "Tout afficher"
    , showFirst = "Afficher les premiers"
    , showAttendees = "(Afficher\u{00A0}les\u{00A0}participant·e·s)"
    , signInAndWeWillGetYouSignedUpForThatEvent = "Connecte-toi et nous t'inscrirons pour cet événement"
    , signInAndWeWillGetYouSignedUpForThe = \eventName -> "Connecte-toi et nous t'inscrirons pour l'événement \"" ++ eventName ++ "\""
    , sinceThisIsYourFirstGroupWeRecommendYouReadThe = "Comme c'est ton premier groupe, nous te recommandons de lire les "
    , sorryThatGroupNameIsAlreadyBeingUsed = "Désolé·e, ce nom de groupe est déjà utilisé."
    , stopNotifyingMeOfNewEvents = "Ne plus me notifier des nouveaux événements"
    , submit = "Valider"
    , subscribedGroups = "Groupes auxquels je suis abonné·e"
    , terms = "conditions"
    , theEventCanTStartInThePast = "L'événement ne peut pas commencer dans le passé"
    , theEventIsTakingPlaceNowAt = "• L'événement a lieu actuellement à "
    , theEventWillTakePlaceAt = "• L'événement aura lieu à "
    , theLinkYouUsedIsEitherInvalidOrHasExpired = "Le lien que tu as utilisé est invalide ou a expiré."
    , theMostImportantRuleIs = "La règle la plus importante est"
    , theStartTimeCanTBeChangedSinceTheEventHasAlreadyStarted = "L'heure de début ne peut pas être modifiée car l'événement a déjà commencé."
    , thisEventDoesNotExist = "Cet événement n'existe pas."
    , thisEventSomehowDoesNotExistTryRefreshingThePage = "Cet événement n'existe pas (essaie de rafraîchir la page ?)"
    , thisEventWasCancelled = "Cet événement a été annulé "
    , thisEventWillBeInPerson = "Cet événement se déroulera en personne"
    , thisEventWillBeOnline = "Cet événement se déroulera en ligne"
    , thisEventWillBeOnlineAndInPerson = "Cet événement se déroulera en ligne et en personne"
    , thisGroupHasTooManyEvents = "Ce groupe a trop d'événements"
    , thisGroupWasCreatedOn = "Ce groupe a été créé le "
    , timeDiffToString = diffToStringFrench
    , timeValueMissing = "Heure manquante"
    , title = "Événement"
    , tos = "Conditions d'utilisation"
    , tosMarkdown = \privacyRoute codeOfConductRoute -> """

#### Version 1.0 – Juin 2021

### 🤔 Qu'est-ce que Meetdown

Ces conditions légales sont entre toi et meetdown.app (« nous », « notre », « Meetdown », le logiciel) et tu acceptes ces conditions en utilisant le service Meetdown.

Tu devrais lire ce document en même temps que notre [Notice de confidentialité](""" ++ privacyRoute ++ """).

### 💬 Comment nous contacter

N'hésite pas à nous contacter par email à [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """)

Nous te contacterons en anglais 🇬🇧 et en Emoji 😃.


### 🤝🏽 Garanties et attentes

Meetdown ne fait aucune garantie.

Le [code source de Meetdown](https://github.com/MartinSStewart/meetdown) est open source donc les utilisateurs techniques peuvent faire leur propre évaluation du risque.

Le logiciel est fourni "tel quel", sans aucune garantie, expresse ou implicite, y compris mais sans s'y limiter les garanties de qualité marchande, d'adaptation à un usage particulier et d'absence de contrefaçon.

Nous attendons de tous les utilisateurs qu'ils se comportent conformément au [Code de conduite](""" ++ codeOfConductRoute ++ """).


### 💵 Coût

Meetdown est un produit gratuit.


### 😔 Comment faire une réclamation

Si tu as une réclamation, n'hésite pas à nous contacter et nous ferons de notre mieux pour résoudre le problème.

Veuillez consulter "Comment nous contacter" ci-dessus.


### 📝 Modifications de cet accord

Cet accord sera toujours disponible sur meetdown.app.

Si nous apportons des modifications, nous t'en informerons une fois que nous les aurons apportées.

Si tu n'es pas d'accord avec ces modifications, tu peux fermer ton compte en appuyant sur "Supprimer le compte" sur ta page de profil.

Nous détruirons toutes les données de ton compte, sauf si nous devons les conserver pour une raison exposée dans notre [Politique de confidentialité](""" ++ privacyRoute ++ """).

### 😭 Fermer ton compte

Pour fermer ton compte, tu peux appuyer sur le bouton "Supprimer le compte" sur ta page de profil.

Nous pouvons fermer ton compte en te donnant au moins une semaine d'avance.

Nous pouvons fermer ton compte immédiatement si nous pensons que tu as :

- Violé les conditions de cet accord
- Mis notre position dans laquelle nous pourrions enfreindre la loi
- Enfreint la loi ou tenté de l'enfreindre
- Fourni des informations fausses à tout moment
- Été abusif envers quiconque chez Meetdown ou un membre de notre communauté

"""
    , twoPeopleOnAVideoConference = "Deux personnes sur une vidéoconférence"
    , uncancelEvent = "Annuler l'annulation de l'événement"
    , uploadImage = "Télécharger une image"
    , userNotFound = "Utilisateur introuvable"
    , valueMustBeGreaterThan0 = "La valeur doit être supérieure à 0."
    , weDontSellYourDataWeDontShowAdsAndItsFree = "Nous ne vendons pas vos données, nous ne montrons pas de publicités et c'est gratuit."
    , welcomePage = "Bienvenue à l'événement !"
    , whatDoYouWantPeopleToKnowAboutYou = "Que veux-tu que les gens sachent à propos de toi ?"
    , whatSTheNameOfYourGroup = "Comment veux-tu appeler ton groupe ?"
    , whenDoesItStart = "Quand est-ce que ça commence ?"
    , youCanDoThatHere = "Tu peux le faire ici."
    , youCanTEditEventsThatHaveAlreadyHappened = "Tu ne peux pas modifier les événements qui ont déjà eu lieu"
    , youCanTEditTheStartTimeOfAnEventThatIsOngoing = "Tu ne peux pas modifier l'heure de début d'un événement qui est en cours"
    , youHavenTCreatedAnyGroupsYet = "Tu n'as pas encore créé de groupes. "
    , youNeedToAllowAtLeast2PeopleToJoinTheEvent = "Tu dois autoriser au moins 2 personnes à rejoindre l'événement."
    , yourEmailAddress = "Ton adresse email"
    , yourName = "Ton nom"
    , yourNameCantBeEmpty = "Ton nom ne peut pas être vide"
    }


spanishTexts : Texts
spanishTexts =
    { addEvent = "Añadir un evento"
    , addressTooLong = \length maxLength -> "La dirección es de " ++ String.fromInt length ++ " caracteres. Manténgase por debajo de " ++ String.fromInt maxLength ++ "."
    , addressTooShort = \length minLength -> "La dirección es de " ++ String.fromInt length ++ " caracteres. Debe contener al menos " ++ String.fromInt minLength ++ "."
    , aLoginEmailHasBeenSentTo = "Se ha enviado un correo electrónico de inicio de sesión a "
    , anAccountDeletionEmailHasBeenSentTo = "Se ha enviado un correo electrónico de eliminación de cuenta a "
    , andNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "y un participante anónimo"

            else
                "y " ++ String.fromInt attendeeCount ++ " participantes anónimos"
    , andOneNanonymousNattendee = "Y un\nparticipante\nanónimo"
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests = "Un lugar para unirse a grupos de personas con intereses compartidos"
    , beginsIn = "Comienza en "
    , belowNCharactersPlease = \n -> "Por debajo de " ++ String.fromInt n ++ " caracteres, por favor"
    , buttonOnAGroupPage = "\" en la página de un grupo."
    , byContinuingYouAgreeToThe = "Al continuar, acepta los "
    , cancel = "Cancelar"
    , cancelChanges = "Cancelar cambios"
    , cancelEvent = "Cancelar evento"
    , checkYourSpamFolderIfYouDonTSeeIt = "Revise su buzón de basura si no lo ve."
    , chooseWhatTypeOfEventThisIs = "Elija qué tipo de evento es"
    , codeOfConduct = "Código de conducta"
    , codeOfConduct1 = "Aquí hay algunos consejos para respetar la regla \"no ser grosero\":"
    , codeOfConduct2 = "• Respete a las personas independientemente de su raza, sexo, identidad sexual, nacionalidad, apariencia o cualquier otra característica relacionada."
    , codeOfConduct3 = "• Sea respetuoso con los organizadores de grupos. Invierten su tiempo en coordinar un evento y están dispuestos a invitar a personas que no conocen. ¡No les traiciones su confianza!"
    , codeOfConduct4 = "• Para los organizadores de grupos: asegúrese de que la gente se sienta incluida. Es difícil para la gente participar si se sienten como extranjeros."
    , codeOfConduct5 = "• Si alguien esta siendo grosero, eso no es una excusa para ser grosero de regreso. Pídeles que paren y, si no funciona, evítalos y explica el problema aquí "
    , copyPreviousEvent = "Copiar evento anterior"
    , createEvent = "Crear evento"
    , createGroup = "Crear grupo"
    , creatingOne = "crear uno"
    , creditGoesTo = ". Créditos a "
    , dateValueMissing = "Falta la fecha"
    , daysUntilEvent = \days -> "Días hasta el evento: " ++ String.fromInt days
    , deleteAccount = "Eliminar cuenta"
    , deleteGroup = "Eliminar grupo"
    , describeWhatYourGroupIsAboutYouCanFillOutThisLater = "Describe de qué es su grupo (puede completar esto más tarde)."
    , description = "Descripción"
    , descriptionTooLong = \descriptionLength maxLength -> "La descripción es de " ++ String.fromInt descriptionLength ++ " caracteres. Manténgase por debajo de " ++ String.fromInt maxLength ++ "."
    , dontBeAJerk = "no seas grosero"
    , edit = "Editar"
    , editEvent = "Editar evento"
    , ended = "Terminó hace "
    , endsIn = "Termina en "
    , enterYourEmailAddress = "Entre su dirección de correo electrónico"
    , enterYourEmailFirst = "Entre su correo electrónico primero"
    , eventCantBeMoreThan = "El evento no puede durar más de "
    , eventCanTStartInThePast = "El evento no puede comenzar en el pasado"
    , eventDescriptionOptional = "Descripción del evento (opcional)"
    , eventDurationText =
        \isPastEvent durationText eventTypeText ->
            if isPastEvent then
                "• Fue un " ++ eventTypeText ++ " de " ++ durationText

            else
                "• Es un " ++ eventTypeText ++ " de " ++ durationText
    , eventName = "Nombre del evento"
    , eventOverlapsOtherEvents = "El evento se superpone a otros eventos"
    , eventOverlapsWithAnotherEvent = "El evento se superpone con otro evento"
    , eventsCanTStartInThePast = "Los eventos no pueden comenzar en el pasado"
    , failedToJoinEventThereArenTAnySpotsLeft = "No se pudo unir al evento, no hay disponibilidad."
    , failedToJoinThisEventDoesnTExistTryRefreshingThePage = "No se pudo unir, este evento no existe (¿intenta actualizar la página?)"
    , failedToLeaveEvent = "No se pudo dejar el evento"
    , faq = "Preguntas frecuentes"
    , faq1 = "No me gusta que meetup.com sea de pago, me envíe correos electrónicos de spam y sea demasiado pesado. También quise intentar hacer algo más sustancial usando "
    , faq2 = " para ver si es factible usarlo en el trabajo."
    , faq3 = "Uso mi propio dinero para alojarlo. Está bien porque está diseñado para ser muy barato de mantener. En el improbable caso de que Meetdown se vuelva muy popular y los costos de alojamiento se vuelvan demasiado altos, pediré donaciones."
    , faqQuestion1 = "¿Quién está detrás de todo esto?"
    , faqQuestion2 = "¿Por qué crear este sitio web?"
    , faqQuestion3 = "Si este sitio web es gratuito y no vende sus datos, ¿cómo se financia?"
    , forHelpingMeOutWithPartsOfTheApp = " para ayudarme con algunas partes de la aplicación."
    , formatDate =
        let
            monthToName : Month -> String
            monthToName m =
                case m of
                    Jan ->
                        "enero"

                    Feb ->
                        "febrero"

                    Mar ->
                        "marzo"

                    Apr ->
                        "abril"

                    May ->
                        "mayo"

                    Jun ->
                        "junio"

                    Jul ->
                        "julio"

                    Aug ->
                        "agosto"

                    Sep ->
                        "septiembre"

                    Oct ->
                        "octubre"

                    Nov ->
                        "noviembre"

                    Dec ->
                        "diciembre"

            weekdayToName : Weekday -> String
            weekdayToName wd =
                case wd of
                    Mon ->
                        "lunes"

                    Tue ->
                        "martes"

                    Wed ->
                        "miércoles"

                    Thu ->
                        "jueves"

                    Fri ->
                        "viernes"

                    Sat ->
                        "sábado"

                    Sun ->
                        "domingo"

            withOrdinalSuffix : Int -> String
            withOrdinalSuffix n =
                String.fromInt n ++ "º"

            dateLanguage : Date.Language
            dateLanguage =
                { monthName = monthToName
                , monthNameShort = monthToName >> String.left 3
                , weekdayName = weekdayToName
                , weekdayNameShort = weekdayToName >> String.left 3
                , dayWithSuffix = withOrdinalSuffix
                }
        in
        Date.formatWithLanguage dateLanguage "ddd MMMM"
    , frequentQuestions = "Preguntas frecuentes"
    , futureEvents = "Eventos futuros"
    , goToHomepage = "Ir a la página de inicio"
    , group1 = "Todavía no está suscrito a ningún grupo. Puede hacerlo por presionando la tecla \""
    , groupDescription = "Descripción del grupo"
    , groupName = "Nombre del grupo"
    , groupNotFound = "Grupo no encontrado"
    , hideU_00A0Attendees = "(Ocultar\u{00A0}asistentes)"
    , hoursLong = " horas."
    , howManyHoursLongIsIt = "¿Cuántas horas dura?"
    , howManyPeopleCanJoinLeaveThisEmptyIfThereSNoLimit = "¿Cuántas personas pueden unirse? (Deje esto vacío si no hay límite)"
    , ifYouDontSeeTheEmailCheckYourSpamFolder = "Si no lo ves, revisa tu buzón de basura."
    , imageEditor = "Editor de imágenes"
    , info = "Info"
    , inPersonEvent = "evento en persona 🤝"
    , invalidDateFormatExpectedSomethingLike_2020_01_31 = "Formato de fecha no válido. Se esperaba algo como 2020-01-31"
    , invalidEmailAddress = "Dirección de correo electrónico no válida"
    , invalidInput = "Entrada no válida. Escriba algo como 1 o 2.5"
    , invalidTimeFormatExpectedSomethingLike_22_59 = "Formato de hora no válido. Se esperaba algo como 22:59"
    , invalidUrlLong = "URL no válido. Entre algo como https://my-hangouts.com o déjelo en blanco"
    , invalidValueChooseAnIntegerLike5Or30OrLeaveItBlank = "Valor no válido. Elija un entero como 5 o 30, o déjelo en blanco."
    , isItI = "Soy yo, "
    , itsTakingPlaceAt =
        \isPastEvent ->
            if isPastEvent then
                "• Estaba en "

            else
                "• Está en "
    , iWantThisGroupToBePubliclyVisible = "Quiero que este grupo sea visible públicamente"
    , iWantThisGroupToBeUnlistedPeopleCanOnlyFindItIfYouLinkItToThem = "Quiero que este grupo no sea listado (las personas solo pueden encontrarlo si se lo enlazas)"
    , joinEvent = "Unirse al evento"
    , just_1AnonymousAttendee = "• Solo 1 asistente anónimo"
    , justNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "Un asistente anónimo"

            else
                String.fromInt attendeeCount ++ " asistentes anónimos"
    , keepItBelowNCharacters = \n -> "Manténgalo debajo de " ++ String.fromInt n ++ " caracteres"
    , leaveEvent = "Dejar el evento"
    , linkThatWillBeShownWhenTheEventStartsOptional = "Enlace que se mostrará cuando comience el evento (opcional)"
    , loading = "Cargando"
    , login = "Registrarse / Iniciar sesión"
    , logout = "Cerrar sesión"
    , makeGroupPublic = "Hacer público el grupo"
    , makeGroupUnlisted = "Hacer no listado el grupo"
    , meetingAddressOptional = "Dirección de reunión (opcional)"
    , moderationHelpRequest = "Solicitud de ayuda para la moderación"
    , myGroups = "Mis grupos"
    , nameMustBeAtLeast = \minLength -> "El nombre debe tener al menos " ++ String.fromInt minLength ++ " caracteres."
    , nameMustBeAtMost = \maxLength -> "El nombre debe tener como máximo " ++ String.fromInt maxLength ++ " caracteres."
    , newEvent = "Nuevo evento"
    , newGroup = "Nuevo grupo"
    , nextEventIsIn = "El próximo evento es en "
    , noGroupsYet = "Todavía no tienes grupos. Comienza por "
    , noNewEventsHaveBeenPlannedYet = "Aún no se han planificado nuevos eventos."
    , noOneAttended = "• Nadie asistió 💔"
    , noOnePlansOnAttending = "• Nadie planea asistir"
    , notifyMeOfNewEvents = "Notificarme de nuevos eventos"
    , numberOfHours =
        \nbHours ->
            if nbHours == "1" then
                "1 hora"

            else
                nbHours ++ " horas"
    , numberOfMinutes =
        \nbMinutes ->
            if nbMinutes == "1" then
                "1 minuto"

            else
                nbMinutes ++ " minutos"
    , onePersonAttended = "• Una persona asistió"
    , onePersonAttendedItWasYou = "• Una persona asistió (fue usted)"
    , onePersonIsAttending = "• Una persona asistirá"
    , onePersonIsAttendingItSYou = "• Una persona asistirá (es usted)"
    , onePersonPlansOnAttending = "• Una persona planea asistir"
    , onePersonPlansOnAttendingItSYou = "• Una persona planea asistir (es usted)"
    , ongoingEvent = "Evento en curso"
    , onlineAndInPersonEvent = "evento en línea y en persona 🤝💻"
    , onlineEvent = "evento en línea 💻"
    , oopsSomethingWentWrongRenderingThisPage = "¡Vaya! Algo salió mal al renderizar esta página."
    , or = " o "
    , organizer = "Organizador"
    , pastEvents = "Eventos pasados"
    , peoplePlanOnAttending =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " gente planean en asistir"
                ++ (if isAttending then
                        " (incluyéndote)"

                    else
                        ""
                   )
    , peopleAreAttending =
        \attendeeCount isAttending ->
            if isAttending then
                "• Usted y " ++ String.fromInt (attendeeCount - 1) ++ " otras personas participan"

            else
                "• " ++ String.fromInt attendeeCount ++ " personas participan"
    , peopleAttended =
        \attendeeCount isAttending ->
            if isAttending then
                "• Usted y " ++ String.fromInt (attendeeCount - 1) ++ " otras personas han participado"

            else
                "• " ++ String.fromInt attendeeCount ++ " personas han participado"
    , pickAVisibilitySetting = "Elija una configuración de visibilidad"
    , pressTheLinkInItToConfirmDeletingYourAccount = "Presione el enlace para confirmar la eliminación de su cuenta."
    , privacy = "Privacidad"
    , privacyMarkdown =
        \termsOfServiceRoute ->
            """
#### Version 1.0 – Junio 2021

Nos comprometemos a proteger y respetar su privacidad. Si tiene alguna pregunta sobre sus datos personales, póngase en contacto con nosotros por correo electrónico a [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).

### 👀 Las informaciones que recopilamos sobre usted

#### - Información sobre cookies

Utilizamos una sola cookie de sesión persistente segura httpOnly para reconocer su navegador y mantenerlo conectado.

Otras cookies pueden introducirse en el futuro, y si es así, nuestra política de privacidad se actualizará en ese momento.


#### - Información proporcionada a través de nuestro servicio o nuestro sitio web

- Por ejemplo, cuando se registra en el servicio y proporciona detalles como su nombre y dirección de correo electrónico

Puede ocurrir que nos proporcione información «sensible», que incluye cosas como su raza, sus opiniones políticas, sus creencias religiosas, sus detalles de afiliación sindical o sus datos biométricos. No utilizaremos esta información de acuerdo con la ley.


### 🔍 Cómo usamos su información

Para proporcionar nuestros servicios, los utilizamos para:

- Ayudarnos a administrar su cuenta

- Enviarle recordatorios de eventos a los que asistió

Para cumplir con nuestras obligaciones legales, los utilizamos para:

- Prevenir actividades ilegales como la piratería y el fraude

Con su permiso, los utilizamos para:

- Promocionar y comunicar nuestros productos y servicios donde pensamos que le interesará por correo electrónico. Si lo desea, siempre puede darse de baja de la recepción de estos correos electrónicos.


### 🤝 Quién compartimos su información

Podemos compartir su información personal con:

- Cualquier persona que trabaje para nosotros cuando necesite hacer su trabajo.
- Cualquier persona a la que nos haya dado su autorización explícita para compartir su información.

También compartiremos su información para cumplir con la ley; para hacer cumplir nuestros [Términos de servicio](""" ++ termsOfServiceRoute ++ """) o otros acuerdos; o para proteger los derechos, la propiedad o la seguridad de nosotros, de nuestros usuarios o de otros.

### 📁 Cuánto tiempo conservamos su información

Conservamos sus datos mientras utilice Meetdown, y durante 1 año después de eso para cumplir con la ley. En algunos casos, como casos de fraude, podemos conservar los datos más tiempo si es necesario y / o la ley nos obliga a hacerlo.

### ✅ Sus derechos

Tiene derecho a:

- Acceder a los datos personales que tenemos sobre usted, o a obtener una copia de ellos.
- Solicitar que corrijamos datos incorrectos.
- Solicitar que eliminemos, bloqueemos o elimine sus datos, aunque por razones legales, a veces no podemos hacerlo.
- Oponerse al uso de sus datos para fines de marketing directo y en ciertas circunstancias, para fines de investigación y estadísticas.
- Retirar su consentimiento que anteriormente le dimos.

Para hacerlo, comuníquese con nosotros por correo electrónico a [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).

### 🔒 Dónde almacenamos o enviamos sus datos

Podemos transferir y almacenar los datos que recopilamos sobre usted en algún lugar fuera de la Unión Europea («UE»). Las personas que trabajan para nosotros o nuestros proveedores fuera de la UE también pueden tratar sus datos.

Podemos compartir datos con organizaciones y países que:

- La Comisión Europea dice que tienen una protección de datos adecuada, o
- Hemos concluido cláusulas de protección de datos estándar con.

### 😔 Cómo hacer una queja

Si tiene una queja, comuníquese con nosotros por correo electrónico a [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """) y haremos todo lo posible para resolver el problema.

### 📝 Cambios en esta política

Publicaremos cualquier cambio que hagamos a nuestra política de privacidad en esta página y, si son cambios importantes, se lo haremos saber por correo electrónico.
"""
    , privacyNotice = "Aviso de privacidad"
    , profile = "Perfil"
    , readMore = "Leer más"
    , recancelEvent = "Reanular el evento"
    , reset = "Reiniciar"
    , save = "Guardar"
    , saveChanges = "Guardar cambios"
    , saving = "Guardando..."
    , search = "Buscar"
    , searchForGroups = "Buscar grupos"
    , subscribingToOne = "suscribiendo a un grupo."
    , searchResultsFor = "Resultados de búsqueda para "
    , showAll = "Mostrar todo"
    , showFirst = "Mostrar primero"
    , showAttendees = "(Mostrar\u{00A0}asistentes)"
    , signInAndWeWillGetYouSignedUpForThatEvent = "Inicie sesión y nos suscribiremos a ese evento"
    , signInAndWeWillGetYouSignedUpForThe = \eventName -> "Acceda su perfil y lo suscribiremos al evento \"" ++ eventName ++ "\""
    , sinceThisIsYourFirstGroupWeRecommendYouReadThe = "Como es su primer grupo, le recomendamos que lea el "
    , sorryThatGroupNameIsAlreadyBeingUsed = "Lo sentimos, ese nombre de grupo ya está en uso."
    , stopNotifyingMeOfNewEvents = "Dejar de notificarme de nuevos eventos"
    , submit = "Someter"
    , subscribedGroups = "Grupos a los que me he suscrito"
    , terms = "términos"
    , theEventCanTStartInThePast = "El evento no puede comenzar en el pasado"
    , theEventIsTakingPlaceNowAt = "• El evento está teniendo lugar ahora en "
    , theEventWillTakePlaceAt = "• El evento tendrá lugar en "
    , theLinkYouUsedIsEitherInvalidOrHasExpired = "El enlace que usó no es válido o ha caducado."
    , theMostImportantRuleIs = "La regla más importante es"
    , theStartTimeCanTBeChangedSinceTheEventHasAlreadyStarted = "La hora de inicio no se puede cambiar porque el evento ya ha comenzado."
    , thisEventDoesNotExist = "Este evento no existe."
    , thisEventSomehowDoesNotExistTryRefreshingThePage = "Este evento no existe (¿intente actualizar la página?)"
    , thisEventWasCancelled = "Este evento fue cancelado hace "
    , thisEventWillBeInPerson = "Este evento será en persona"
    , thisEventWillBeOnline = "Este evento será en línea"
    , thisEventWillBeOnlineAndInPerson = "Este evento será en línea y en persona"
    , thisGroupHasTooManyEvents = "Este grupo tiene demasiados eventos"
    , thisGroupWasCreatedOn = "Este grupo fue creado el "
    , timeDiffToString = diffToStringSpanish
    , timeValueMissing = "Falta el tiempo"
    , title = "Evento"
    , tos = "Términos de uso"
    , tosMarkdown = \privacyRoute codeOfConductRoute -> """

#### Version 1.0 – Junio 2021

### 🤔 Qué es Meetdown

Estos términos legales son entre usted y meetdown.app (« nosotros », « nuestro », « Meetdown », el software) y acepta estos términos al usar el servicio Meetdown.

Debería leer este documento al mismo tiempo que nuestra [Política de privacidad](""" ++ privacyRoute ++ """).

### 💬 Cómo contactarnos

Por favor contáctenos por correo electrónico a [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """)

Nos pondremos en contacto con usted en inglés 🇬🇧 y en Emoji 😃.


### 🤝🏽 Garantías y expectativas

Meetdown no hace ninguna garantía.

El [código fuente de Meetdown](https://github.com/MartinSStewart/meetdown) es de código abierto, por lo que los usuarios técnicos pueden hacer su propia evaluación del riesgo.

El software se proporciona "tal cual", sin ninguna garantía, expresa o implícita, incluidas, entre otras, las garantías de calidad comercial, adecuación para un uso particular y ausencia de infracción.

Esperamos que todos los usuarios se comporten de acuerdo con el [Código de conducta](""" ++ codeOfConductRoute ++ """).

### 💵 Costo

Meetdown es un producto gratuito.


### 😔 Cómo hacer una reclamación

Si tiene una reclamación, comuníquese con nosotros y haremos todo lo posible para resolver el problema.

Consulte "Cómo contactarnos" arriba.


### 📝 Modificaciones a este acuerdo

Este acuerdo siempre estará disponible en meetdown.app.

Si hacemos modificaciones, le informaremos una vez que las hayamos realizado.

Si no está de acuerdo con estos cambios, puede cerrar su cuenta presionando el botón "Eliminar cuenta" en su página de perfil.

Destruiremos todos los datos de su cuenta, excepto si debemos conservarlos por una razón expuesta en nuestra [Política de privacidad](""" ++ privacyRoute ++ """).

### 😭 Cerrar su cuenta

Para cerrar su cuenta, puede presionar el botón "Eliminar cuenta" en su página de perfil.

Podemos cerrar su cuenta al darle al menos una semana de antelación.

Podemos cerrar su cuenta de inmediato si pensamos que ha:

- Violado los términos de este acuerdo
- Puso nuestra posición en la que podríamos infringir la ley
- Infringió la ley o intentó infringirla
- Proporcionó información falsa en cualquier momento
- Fue abusivo con cualquier persona en Meetdown o miembro de nuestra comunidad

"""
    , twoPeopleOnAVideoConference = "Dos personas en una videoconferencia"
    , uncancelEvent = "Deshacer la cancelación del evento"
    , uploadImage = "Subir un imagen"
    , userNotFound = "Usuario no encontrado"
    , valueMustBeGreaterThan0 = "El valor debe ser mayor que 0."
    , weDontSellYourDataWeDontShowAdsAndItsFree = "No vendemos tus datos, no mostramos anuncios y es gratis."
    , welcomePage = "¡Bienvenido al evento!"
    , whatDoYouWantPeopleToKnowAboutYou = "¿Qué quieres que la gente sepa de ti?"
    , whatSTheNameOfYourGroup = "¿Cuál es el nombre de tu grupo?"
    , whenDoesItStart = "¿Cuándo comienza?"
    , youCanDoThatHere = "Puedes hacerlo aquí."
    , youCanTEditEventsThatHaveAlreadyHappened = "No puedes editar eventos que ya han ocurrido"
    , youCanTEditTheStartTimeOfAnEventThatIsOngoing = "No puedes editar la hora de inicio de un evento que está en curso"
    , youHavenTCreatedAnyGroupsYet = "Aún no has creado grupos. "
    , youNeedToAllowAtLeast2PeopleToJoinTheEvent = "Necesitas permitir que al menos 2 personas se unan al evento."
    , yourEmailAddress = "Tu correo electrónico"
    , yourName = "Tu nombre"
    , yourNameCantBeEmpty = "Tu nombre no puede estar vacío"
    }


thaiTexts : Texts
thaiTexts =
    { addEvent = "เพิ่มกิจกรรม"
    , addressTooLong = \length maxLength -> "ที่อยู่ยาว " ++ String.fromInt length ++ " ตัวอักษร กรุณาตัดให้สั้นลงอยู่ใน " ++ String.fromInt maxLength ++ " ตัวอักษร"
    , addressTooShort = \length minLength -> "ที่อยู่สั้น " ++ String.fromInt length ++ " ตัวอักษร ต้องมีอย่างน้อย " ++ String.fromInt minLength ++ " ตัวอักษร"
    , aLoginEmailHasBeenSentTo = "อีเมลล็อกอินถูกส่งไปที่ "
    , anAccountDeletionEmailHasBeenSentTo = "อีเมลสำหรับลบบัญชีถูกส่งไปที่ "
    , andNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "และมีผู้เข้าร่วมที่ไม่ระบุชื่อ\nอีกหนึ่งคน"

            else
                "และมีผู้เข้าร่วมที่ไม่ระบุชื่อ\nอีก " ++ String.fromInt attendeeCount ++ " คน"
    , andOneNanonymousNattendee = "และมีผู้เข้าร่วมที่ไม่ระบุชื่อ\nอีกหนึ่งคน"
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests = "สถานที่ที่คุณสามารถเข้าร่วมกับกลุ่มคนที่มีความสนใจเดียวกัน"
    , beginsIn = "เริ่มในอีก "
    , belowNCharactersPlease = \n -> "ต้องมีตัวอักษรน้อยกว่า " ++ String.fromInt n ++ " ตัวอักษร"
    , buttonOnAGroupPage = "\" ปุ่มในหน้ากลุ่ม"
    , byContinuingYouAgreeToThe = "โดยการดำเนินการต่อคุณยอมรับ "
    , cancel = "ยกเลิก"
    , cancelChanges = "ยกเลิกการเปลี่ยนแปลง"
    , cancelEvent = "ยกเลิกกิจกรรม"
    , checkYourSpamFolderIfYouDonTSeeIt = "กรุณาตรวจสอบโฟลเดอร์สแปมหากคุณไม่เห็น"
    , chooseWhatTypeOfEventThisIs = "เลือกประเภทของกิจกรรมนี้"
    , codeOfConduct = "ประเด็นสำคัญในการปฏิบัติ"
    , codeOfConduct1 = "นี่คือคำแนะนำเพื่อให้คุณปฏิบัติตามกฎ \"อย่าทำตัวเป็นคนไม่ดี\":"
    , codeOfConduct2 = "• ให้ความเคารพกับผู้คนไม่ว่าจะเป็นเรื่องเชื้อชาติ, เพศ, ตัวตนทางเพศ, สัญชาติ, รูปลักษณ์, หรือลักษณะอื่นๆ ที่เกี่ยวข้อง."
    , codeOfConduct3 = "• โปรดให้ความเคารพกับผู้จัดตั้งกลุ่มนี้ เนื่องจากพวกเขาใช้เวลาประสานงานการจัดกิจกรรม และยินดีที่จะเรียนเชิญทุกคนเข้าร่วมกิจกรรม อย่าทำลายความไว้วางใจที่พวกเขามีให้คุณ!"
    , codeOfConduct4 = "• สำหรับผู้จัดกลุ่ม: ทำให้คนรู้สึกว่าพวกเขาเป็นส่วนหนึ่งของกลุ่ม คนจะไม่สามารถเข้าร่วมได้ถ้าพวกเขารู้สึกว่าตัวเองเป็นคนนอก."
    , codeOfConduct5 = "• ถ้ามีคนทำตัวไม่ดี นั่นไม่ใช่เหตุผลให้คุณต้องทำตัวไม่ดีกลับ โปรดขอให้พวกเขาหยุด หากการขอให้พวกเขาหยุดไม่สำเร็จ ควรหลีกเลี่ยงพวกเขาและรายงานปัญหาที่นี่ "
    , copyPreviousEvent = "คัดลอกกิจกรรมก่อนหน้านี้"
    , createEvent = "สร้างกิจกรรม"
    , createGroup = "สร้างกลุ่ม"
    , creatingOne = "การสร้าง"
    , creditGoesTo = " มอบความดีความชอบให้กับ "
    , dateValueMissing = "ขาดข้อมูลวันที่"
    , daysUntilEvent = \days -> "วันจนถึงกิจกรรม: " ++ String.fromInt days
    , deleteAccount = "ลบบัญชี"
    , deleteGroup = "ลบกลุ่ม"
    , describeWhatYourGroupIsAboutYouCanFillOutThisLater = "อธิบายว่ากลุ่มของคุณเกี่ยวกับอะไร (คุณสามารถกรอกนี้ได้ภายหลัง)"
    , description = "คำอธิบาย"
    , descriptionTooLong = \descriptionLength maxLength -> "คำอธิบายยาว " ++ String.fromInt descriptionLength ++ " ตัวอักษร ต้องสั้นลงเป็น " ++ String.fromInt maxLength ++ " ตัวอักษร"
    , dontBeAJerk = "อย่าทำตัวเป็นคนไม่ดี"
    , edit = "แก้ไข"
    , editEvent = "แก้ไขกิจกรรม"
    , ended = "จบแล้ว "
    , endsIn = "จบในอีก "
    , enterYourEmailAddress = "ใส่ที่อยู่อีเมลของคุณ"
    , enterYourEmailFirst = "ใส่อีเมลของคุณก่อน"
    , eventCantBeMoreThan = "กิจกรรมไม่สามารถมากกว่า "
    , eventCanTStartInThePast = "กิจกรรมไม่สามารถเริ่มในอดีต"
    , eventDescriptionOptional = "คำอธิบายกิจกรรม (เลือกได้)"
    , eventDurationText =
        \isPastEvent durationText eventTypeText ->
            if isPastEvent then
                "• นี่เป็นกิจกรรม " ++ eventTypeText ++ " ที่มีระยะเวลา " ++ durationText

            else
                "• นี่คือกิจกรรม " ++ eventTypeText ++ " ที่จะมีระยะเวลา " ++ durationText
    , eventName = "ชื่อกิจกรรม"
    , eventOverlapsOtherEvents = "กิจกรรมนี้ซ้อนทับกับกิจกรรมอื่นๆ"
    , eventOverlapsWithAnotherEvent = "กิจกรรมนี้ซ้อนทับกับกิจกรรมอื่น"
    , eventsCanTStartInThePast = "กิจกรรมไม่สามารถเริ่มในอดีต"
    , failedToJoinEventThereArenTAnySpotsLeft = "ไม่สามารถเข้าร่วมกิจกรรม ไม่มีที่ว่างอีกแล้ว"
    , failedToJoinThisEventDoesnTExistTryRefreshingThePage = "ไม่สามารถเข้าร่วม กิจกรรมนี้ไม่มีอยู่ (ลองรีเฟรชหน้าเว็บ?)"
    , failedToLeaveEvent = "ไม่สามารถออกจากกิจกรรม"
    , faq = "คำถามที่พบบ่อย"
    , faq1 = "ฉันไม่ชอบที่ meetup.com เรียกเก็บเงิน ส่งอีเมลซับซ้อนถึงฉัน และดูอิ่มตัว ฉันยังอยากลองทำบางสิ่งที่มีความหมายมากขึ้นโดยใช้ "
    , faq2 = "เพื่อดูว่าเป็นไปได้ในการใช้ที่ทำงานหรือไม่"
    , faq3 = "ฉันเพียงแค่ใช้เงินส่วนตัวเพื่อโฮสต์มัน สิ่งนี้ไม่เป็นไรเพราะได้ออกแบบมาเพื่อให้มีค่าใช้จ่ายในการทำงานน้อยที่สุด ในกรณีที่ Meetdown ได้รับความนิยมอย่างมากและค่าใช้จ่ายในการโฮสต์เริ่มต้นมากขึ้น ฉันจะขอบริจาค"
    , faqQuestion1 = "ใครคือผู้ที่อยู่เบื้องหลังทั้งหมดนี้?"
    , faqQuestion2 = "ทำไมเว็บไซต์นี้ถึงถูกสร้างขึ้น?"
    , faqQuestion3 = "ถ้าเว็บไซต์นี้ฟรีและไม่ได้วางโฆษณาหรือขายข้อมูล มันสามารถรักษาตัวเองได้อย่างไร?"
    , forHelpingMeOutWithPartsOfTheApp = " สำหรับการช่วยฉันในส่วนของแอป"
    , formatDate = Date.format "MMMM ddd"
    , frequentQuestions = "คำถามที่พบบ่อย"
    , futureEvents = "กิจกรรมในอนาคต"
    , goToHomepage = "ไปที่หน้าหลัก"
    , group1 = "คุณยังไม่ได้สมัครสมาชิกกับกลุ่มใด ๆ คุณสามารถทำได้โดยการกด \""
    , groupDescription = "คำอธิบายกลุ่ม"
    , groupName = "ชื่อกลุ่ม"
    , groupNotFound = "ไม่พบกลุ่ม"
    , hideU_00A0Attendees = "(ซ่อน\u{00A0}ผู้เข้าร่วม)"
    , hoursLong = " ชั่วโมง."
    , howManyHoursLongIsIt = "มันยาวกี่ชั่วโมง?"
    , howManyPeopleCanJoinLeaveThisEmptyIfThereSNoLimit = "มีกี่คนที่สามารถเข้าร่วม (ปล่อยว่างถ้าไม่มีขีดจำกัด)"
    , ifYouDontSeeTheEmailCheckYourSpamFolder = "ถ้าคุณไม่เห็นอีเมล ตรวจสอบโฟลเดอร์สแปมของคุณ"
    , imageEditor = "ตัวแก้ไขรูปภาพ"
    , info = "ข้อมูล"
    , inPersonEvent = "กิจกรรมที่พบกันด้วยตัวเอง 🤝"
    , invalidDateFormatExpectedSomethingLike_2020_01_31 = "รูปแบบวันที่ไม่ถูกต้อง คาดว่าจะมีลักษณะประมาณ 2020-01-31"
    , invalidEmailAddress = "ที่อยู่อีเมลไม่ถูกต้อง"
    , invalidInput = "ข้อมูลที่ป้อนไม่ถูกต้อง เขียนบางอย่างที่เป็นแบบ 1 หรือ 2.5"
    , invalidTimeFormatExpectedSomethingLike_22_59 = "รูปแบบเวลาไม่ถูกต้อง คาดว่าจะมีลักษณะประมาณ 22:59"
    , invalidUrlLong = "URL ไม่ถูกต้อง ใส่บางสิ่งที่เป็นแบบ https://my-hangouts.com หรือปล่อยว่าง"
    , invalidValueChooseAnIntegerLike5Or30OrLeaveItBlank = "ค่าไม่ถูกต้อง เลือกจำนวนเต็มเช่น 5 หรือ 30 หรือปล่อยว่าง"
    , isItI = "ฉันคือ "
    , itsTakingPlaceAt =
        \isPastEvent ->
            if isPastEvent then
                "• มันจัดขึ้นที่ "

            else
                "• มันกำลังจะจัดขึ้นที่ "
    , iWantThisGroupToBePubliclyVisible = "ฉันต้องการให้กลุ่มนี้มองเห็นได้สาธารณะ"
    , iWantThisGroupToBeUnlistedPeopleCanOnlyFindItIfYouLinkItToThem = "ฉันต้องการให้กลุ่มนี้ไม่ปรากฏในรายการ (คนอื่นๆจะสามารถหาเจอกลุ่มนี้ได้เฉพาะเมื่อคุณส่งลิงก์ให้กับพวกเขา)"
    , joinEvent = "เข้าร่วมกิจกรรม"
    , just_1AnonymousAttendee = "• มีเพียง 1 ผู้เข้าร่วมที่ไม่ระบุชื่อ"
    , justNanonymousNattendees =
        \attendeeCount ->
            if attendeeCount == 1 then
                "• มีเพียงผู้เข้าร่วม 1 คนที่ไม่ระบุชื่อ"

            else
                "• มีเพียง " ++ String.fromInt attendeeCount ++ " ผู้เข้าร่วมที่ไม่ระบุชื่อ"
    , keepItBelowNCharacters = \n -> "จำกัดอยู่ใน " ++ String.fromInt n ++ " ตัวอักษร"
    , leaveEvent = "ออกจากกิจกรรม"
    , linkThatWillBeShownWhenTheEventStartsOptional = "ลิงก์ที่จะแสดงเมื่อกิจกรรมเริ่ม (ไม่บังคับ)"
    , loading = "กำลังโหลด"
    , login = "ลงทะเบียน / เข้าสู่ระบบ"
    , logout = "ออกจากระบบ"
    , makeGroupPublic = "ทำให้กลุ่มเป็นสาธารณะ"
    , makeGroupUnlisted = "ทำให้กลุ่มไม่แสดง"
    , meetingAddressOptional = "ที่อยู่สำหรับประชุม (ไม่บังคับ)"
    , moderationHelpRequest = "คำขอความช่วยเหลือในการดูแล"
    , myGroups = "กลุ่มของฉัน"
    , nameMustBeAtLeast = \number -> "ชื่อต้องมีอย่างน้อย " ++ String.fromInt number ++ " ตัวอักษร."
    , nameMustBeAtMost = \number -> "ชื่อยาวเกินไป จำกัดอยู่ใน " ++ String.fromInt number ++ " ตัวอักษร."
    , newEvent = "กิจกรรมใหม่"
    , newGroup = "กลุ่มใหม่"
    , nextEventIsIn = "กิจกรรมถัดไปคือ "
    , noGroupsYet = "คุณยังไม่มีกลุ่ม มาเริ่มต้นโดย "
    , noNewEventsHaveBeenPlannedYet = "ยังไม่มีกิจกรรมใหม่ที่ถูกวางแผน."
    , noOneAttended = "• ไม่มีใครเข้าร่วม 💔"
    , noOnePlansOnAttending = "• ไม่มีใครวางแผนที่จะเข้าร่วม"
    , notifyMeOfNewEvents = "แจ้งเตือนฉันเมื่อมีกิจกรรมใหม่"
    , numberOfHours = \nbHours -> nbHours ++ "\u{00A0}ชั่วโมง"
    , numberOfMinutes = \nbMinutes -> nbMinutes ++ "\u{00A0}นาที"
    , onePersonAttended = "• มีคนเข้าร่วม 1 คน"
    , onePersonAttendedItWasYou = "• มีคนเข้าร่วม 1 คน (คุณเอง)"
    , onePersonIsAttending = "• มีคนเข้าร่วม 1 คน"
    , onePersonIsAttendingItSYou = "• มีคนเข้าร่วม 1 คน (คือคุณ)"
    , onePersonPlansOnAttending = "• มีคนวางแผนที่จะเข้าร่วม 1 คน"
    , onePersonPlansOnAttendingItSYou = "• มีคนวางแผนที่จะเข้าร่วม 1 คน (คือคุณ)"
    , ongoingEvent = "กิจกรรมที่กำลังดำเนินอยู่"
    , onlineAndInPersonEvent = "กิจกรรมออนไลน์และด้วยตัวเอง 🤝💻"
    , onlineEvent = "กิจกรรมออนไลน์ 💻"
    , oopsSomethingWentWrongRenderingThisPage = "โอ้! มีบางอย่างผิดพลาดในการแสดงหน้านี้: "
    , or = " หรือ "
    , organizer = "ผู้จัดงาน"
    , pastEvents = "กิจกรรมในอดีต"
    , peoplePlanOnAttending =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " คนวางแผนที่จะเข้าร่วม"
                ++ (if isAttending then
                        " (รวมถึงคุณ)"

                    else
                        ""
                   )
    , peopleAreAttending =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " คนกำลังเข้าร่วม"
                ++ (if isAttending then
                        " (รวมถึงคุณ)"

                    else
                        ""
                   )
    , peopleAttended =
        \attendeeCount isAttending ->
            "• "
                ++ String.fromInt attendeeCount
                ++ " คนเข้าร่วม"
                ++ (if isAttending then
                        " (รวมถึงคุณ)"

                    else
                        ""
                   )
    , pickAVisibilitySetting = "เลือกการตั้งค่าการมองเห็น"
    , pressTheLinkInItToConfirmDeletingYourAccount = ". กดลิงก์ในนั้นเพื่อยืนยันการลบบัญชีของคุณ."
    , privacy = "ความเป็นส่วนตัว"
    , privacyMarkdown =
        \termsOfServiceRoute ->
            """

#### รุ่น 1.0 – มิถุนายน 2021

เรามุ่งมั่นที่จะปกป้องและเคารพความเป็นส่วนตัวของคุณ หากคุณมีคำถามใด ๆ เกี่ยวกับข้อมูลส่วนบุคคลของคุณ กรุณาสนทนากับเราโดยส่งอีเมลถึงเราที่ [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).


### 👀 ข้อมูลที่เรามีเกี่ยวกับคุณ

#### - ข้อมูลคุกกี้

เราใช้คุกกี้เซสชันที่มีความปลอดภัยที่จะรู้จักเบราว์เซอร์ของคุณและเก็บคุณอยู่ในระบบ

คุกกี้อื่น ๆ อาจจะถูกนำเข้าในอนาคต และหากเป็นเช่นนั้นนโยบายความเป็นส่วนตัวของเราจะได้รับการปรับปรุงในเวลานั้น


#### - ข้อมูลที่ส่งผ่านบริการหรือเว็บไซต์ของเรา

- ตัวอย่างเช่น เมื่อคุณสมัครใช้บริการและให้รายละเอียดเช่นชื่อและอีเมลของคุณ

อาจมีครั้งที่คุณให้เรา 'ข้อมูลที่ละเอียด' ซึ่งรวมถึงสิ่งที่เช่น กำเนิดของคุณ ความคิดเห็นทางการเมือง ความเชื่อทางศาสนา รายละเอียดการเป็นสมาชิกสหภาพแรงงาน หรือข้อมูลชีวมวล เราจะใช้ข้อมูลนี้โดยปฏิบัติตามกฎหมายอย่างเคร่งครัด


### 🔍 วิธีที่เราใช้ข้อมูลของคุณ

เพื่อให้บริการของเรา เราใช้มันเพื่อ:

- ช่วยเราจัดการบัญชีของคุณ
- ส่งการแจ้งเตือนให้คุณสำหรับกิจกรรมที่คุณได้เข้าร่วม

เพื่อตอบสนองต่อหน้าที่ของเราตามกฎหมาย เราใช้มันเพื่อ:

- ป้องกันกิจกรรมที่ผิดกฎหมาย เช่น การละเมิดสิทธิ์และการฉ้อโกง

ด้วยความยินยอมของคุณ เราใช้มันเพื่อ:

- ตลาดและสื่อสารผลิตภัณฑ์และบริการของเราที่เราคิดว่าจะน่าสนใจของคุณโดยอีเมล คุณสามารถยกเลิกการรับเรื่องเหล่านี้ได้ตลอดเวลาโดยอีเมล


### 🤝 ใครที่เราแบ่งปันข้อมูลกับ

เราอาจจะแบ่งปันข้อมูลส่วนบุคคลของคุณกับ:

- ทุกคนที่ทำงานให้เราเมื่อพวกเขาต้องการมันเพื่อทำงานของพวกเขา
- ทุกคนที่คุณให้เราได้รับอนุญาตอย่างชัดเจนให้แบ่งปันมันกับ

เรายังจะแบ่งปันมันเพื่อปฏิบัติตามกฎหมาย; เพื่อบังคับใช้ [ข้อกำหนดการให้บริการ](""" ++ termsOfServiceRoute ++ """) หรือข้อตกลงอื่น ๆ; หรือเพื่อปกป้องสิทธิ์ ทรัพย์สิน หรือความปลอดภัยของเรา ผู้ใช้ของเรา หรือคนอื่น ๆ

### 📁 วิธีที่เราเก็บข้อมูลของคุณ

เราเก็บข้อมูลของคุณเมื่อคุณใช้ Meetdown และสำหรับ 1 ปีหลังจากนั้น```
เพื่อปฏิบัติตามกฎหมาย ในบางกรณี เช่น การฉ้อโกง เราอาจจะเก็บข้อมูลนานขึ้นหากเราต้องการและ/หรือกฎหมายบังคับให้เราทำ

### ✅ สิทธิ์ของคุณ

คุณมีสิทธิ์:

- ทราบข้อมูลส่วนบุคคลที่เราเก็บเกี่ยวกับคุณหรือได้รับสำเนาของมัน
- ทำให้เราแก้ไขข้อมูลที่ไม่ถูกต้อง
- ขอให้เราลบ 'บล็อก' หรือข้อมูลที่ของคุณ แม้ว่าสำหรับเหตุผลทางกฎหมายเราอาจจะไม่สามารถทำได้เสมอไป
- ขัดขืนไม่ให้เราใช้ข้อมูลของคุณเพื่อการตลาดโดยตรงและในบางกรณี 'ประโยชน์ชอบธรรม' การวิจัยและเหตุผลทางสถิติ
- ถอนความยินยอมที่คุณได้ให้กับเรามาก่อนนี้

เพื่อทำเช่นนี้ กรุณาติดต่อเราโดยส่งอีเมลถึง [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """).


### 🔒 สถานที่ที่เราเก็บหรือส่งข้อมูลของคุณ

เราอาจจะโอนและเก็บข้อมูลที่เราเก็บรวบรวมจากคุณไปยังท somewhereที่อยู่นอกยุโรป ผู้ที่ทำงานให้เราหรือผู้ผลิตของเราที่อยู่นอกยุโรปอาจจะประมวลผลข้อมูลของคุณ

เราอาจแบ่งปันข้อมูลกับองค์กรและประเทศที่:

- คณะกรรมาธิการยุโรปกล่าวว่ามีการป้องกันข้อมูลที่เหมาะสม หรือ
- เราได้ทำข้อตกลงเกี่ยวกับคุ้มครองข้อมูลมาตรฐานกับ


### 😔 วิธีการยื่นเรื่องร้องเรียน

หากคุณมีเรื่องร้องเรียน กรุณาติดต่อเราโดยส่งอีเมลถึง [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """) และเราจะทำทุกทางเพื่อแก้ไขปัญหา


### 📝 การเปลี่ยนแปลงนโยบายนี้

เราจะโพสต์การเปลี่ยนแปลงที่เราทำเกี่ยวกับแจ้งเตือนความเป็นส่วนตัวของเราในหน้านี้และถ้ามีการเปลี่ยนแปลงที่สำคัญเราจะแจ้งให้คุณทราบทางอีเมล

"""
    , privacyNotice = "แจ้งเตือนความเป็นส่วนตัว"
    , profile = "โปรไฟล์"
    , readMore = "อ่านเพิ่มเติม"
    , recancelEvent = "ยกเลิกกิจกรรมอีกครั้ง"
    , reset = "รีเซ็ต"
    , save = "บันทึก"
    , saveChanges = "บันทึกการเปลี่ยนแปลง"
    , saving = "กำลังบันทึก..."
    , search = "ค้นหา"
    , searchForGroups = "ค้นหากลุ่ม"
    , subscribingToOne = "กำลังสมัครสมาชิก"
    , searchResultsFor = "ผลการค้นหาสำหรับ "
    , showAll = "แสดงทั้งหมด"
    , showFirst = "แสดงครั้งแรก"
    , showAttendees = "(แสดง\u{00A0}ผู้เข้าร่วม)"
    , signInAndWeWillGetYouSignedUpForThatEvent = "ลงชื่อเข้าใช้และเราจะลงทะเบียนให้คุณเข้าร่วมกิจกรรมนั้น"
    , signInAndWeWillGetYouSignedUpForThe = \eventName -> "ลงชื่อเข้าใช้และเราจะลงทะเบียนให้คุณเข้าร่วม " ++ eventName ++ " กิจกรรม."
    , sinceThisIsYourFirstGroupWeRecommendYouReadThe = "เนื่องจากนี่เป็นกลุ่มแรกของคุณ เราขอแนะนำให้คุณอ่าน "
    , sorryThatGroupNameIsAlreadyBeingUsed = "ขออภัย ชื่อกลุ่มนี้ถูกใช้งานแล้ว"
    , stopNotifyingMeOfNewEvents = "หยุดแจ้งเตือนเหตุการณ์ใหม่"
    , submit = "ส่ง"
    , subscribedGroups = "กลุ่มที่สมัครสมาชิก"
    , terms = "เงื่อนไข"
    , theEventCanTStartInThePast = "กิจกรรมไม่สามารถเริ่มในอดีต"
    , theEventIsTakingPlaceNowAt = "• กิจกรรมกำลังจัดขึ้นในขณะนี้ที่ "
    , theEventWillTakePlaceAt = "• กิจกรรมจะจัดขึ้นที่ "
    , theLinkYouUsedIsEitherInvalidOrHasExpired = "ลิงก์ที่คุณใช้ไม่ถูกต้องหรือหมดอายุแล้ว"
    , theMostImportantRuleIs = "กฎที่สำคัญที่สุดคือ"
    , theStartTimeCanTBeChangedSinceTheEventHasAlreadyStarted = "ไม่สามารถเปลี่ยนเวลาเริ่มต้นเนื่องจากกิจกรรมเริ่มแล้ว"
    , thisEventDoesNotExist = "กิจกรรมนี้ไม่มีอยู่"
    , thisEventSomehowDoesNotExistTryRefreshingThePage = "กิจกรรมนี้ไม่มีอยู่ ลองรีเฟรชหน้า?"
    , thisEventWasCancelled = "กิจกรรมนี้ถูกยกเลิก "
    , thisEventWillBeInPerson = "กิจกรรมนี้จะจัดขึ้นโดยตรง"
    , thisEventWillBeOnline = "กิจกรรมนี้จะจัดขึ้นออนไลน์"
    , thisEventWillBeOnlineAndInPerson = "กิจกรรมนี้จะจัดขึ้นออนไลน์และโดยตรง"
    , thisGroupHasTooManyEvents = "กลุ่มนี้มีกิจกรรมมากเกินไป"
    , thisGroupWasCreatedOn = "กลุ่มนี้ถูกสร้างขึ้นเมื่อ "
    , timeDiffToString = diffToStringEnglish
    , timeValueMissing = "ไม่มีค่าเวลา"
    , title = "กิจกรรม"
    , tos = "ข้อกำหนดในการให้บริการ"
    , tosMarkdown = \privacyRoute codeOfConductRoute -> """

#### รุ่น 1.0 - มิถุนายน 2021

### 🤔 Meetdown คืออะไร

เงื่อนไขกฎหมายเหล่านี้คือสิ่งที่คุณและ meetdown.app (“เรา”, “ของเรา”, “Meetdown”, ซอฟต์แวร์) ตกลงกัน และคุณตกลงตามเงื่อนไขเหล่านี้โดยการใช้บริการ Meetdown

คุณควรอ่านเอกสารนี้พร้อมกับ [Data Privacy Notice](""" ++ privacyRoute ++ """) ของเรา

### 💬 วิธีติดต่อเรา

โปรดแชทกับเราโดยส่งอีเมลถึงเราที่ [""" ++ Env.contactEmailAddress ++ """](mailto:""" ++ Env.contactEmailAddress ++ """)

เราจะติดต่อคุณในภาษาอังกฤษ 🇬🇧 และอีโมจิ 😃

### 🤝🏽 การรับประกันและความคาดหวัง

Meetdown ไม่มีการรับประกัน

[โค้ดที่มาสำหรับ Meetdown](https://github.com/MartinSStewart/meetdown) เป็นโอเพนซอร์สดังนั้นผู้ใช้เทคนิคอาจทำการประเมินความเสี่ยงเอง

ซอฟต์แวร์ให้บริการ "ตามที่เป็น" โดยไม่มีการรับประกันอย่างใด ๆ ไม่ว่าจะชัดแจ้งหรือโดยการอนุมัติ รวมถึงแต่ไม่จำกัดเพียงการรับประกันของการขาย การความเหมาะสมสำหรับวัตถุประสงค์ที่กำหนด และการไม่ละเมิดสิทธิ

ในกรณีใด ๆ ก็ตาม ผู้เขียนหรือผู้ถือลิขสิทธิ์จะไม่รับผิดชอบต่อคำร้องขอ ความเสียหายหรือความรับผิดชอบอื่น ๆ ไม่ว่าจะในการดำเนินคดีของสัญญา ความผิดหรืออื่น ๆ ที่เกิดจาก โดยมาจากหรือในการเชื่อมโยงกับซอฟต์แวร์หรือการใช้หรือการเจรจาอื่น ๆ ในซอฟต์แวร์

เราคาดหวังว่าผู้ใช้ทุกคนจะปฏิบัติตาม [Code of conduct](""" ++ codeOfConductRoute ++ """)


### 💵 ค่าใช้จ่าย

Meetdown เป็นผลิตภัณฑ์ที่ให้บริการฟรี


### 😔 วิธีการยื่นเรื่องร้องเรียน

ถ้าคุณมีเรื่องร้องเรียน กรุณาติดต่อเราและเราจะทำทุกอย่างเพื่อแก้ไขปัญหา

โปรดดู "วิธีติดต่อเรา" ด้านบน


### 📝 การทำการเปลี่ยนแปลงข้อตกลงนี้

ข้อตกลงนี้จะสามารถใช้ได้ตลอดเวลาที่ meetdown.app

หากเราทำการเปลี่ยนแปลง คุณจะได้รับการแจ้งเตือนทันทีหลังจากที่เราทำการเปลี่ยนแปลง

หากคุณไม่เห็นด้วยกับการเปลี่ยนแปลงเหล่านี้ คุณสามารถปิดบัญชีของคุณได้โดยการกด "Delete Account" ที่หน้าโปรไฟล์ของคุณ

เราจะทำลายข้อมูลในบัญชีของคุณ ยกเว้นกรณีที่เราจำเป็นต้องเก็บไว้ตามที่กำหนดไว้ใน [Privacy policy](""" ++ privacyRoute ++ """)


### 😭 การปิดบัญชีของคุณ

เพื่อปิดบัญชีของคุณ คุณสามารถกดที่ปุ่ม "Delete Account" ที่หน้าโปรไฟล์ของคุณ

เราสามารถปิดบัญชีของคุณโดยให้คุณรับทสายเป็นอย่างน้อยหนึ่งสัปดาห์

เราอาจปิดบัญชีของคุณทันทีถ้าเราเชื่อว่าคุณ:

- ฝ่าฝืนข้อตกลงในสัญญานี้
- ทำให้เราอยู่ในสถานการณ์ที่เราอาจฝ่าฝืนกฎหมาย
- ฝ่าฝืนกฎหมายหรือพยายามฝ่าฝืนกฎหมาย
- ให้ข้อมูลที่ไม่จริงกับเราที่ใด ๆ เวลา
- มีพฤติกรรมทารุณโต้เถียงกับบุคคลใด ๆ ที่ Meetdown หรือสมาชิกในชุมชนของเรา

"""
    , twoPeopleOnAVideoConference = "สองคนที่กำลังประชุมผ่านวิดีโอ"
    , uncancelEvent = "ยกเลิกการยกเลิกกิจกรรม"
    , uploadImage = "อัปโหลดรูปภาพ"
    , userNotFound = "ไม่พบผู้ใช้"
    , valueMustBeGreaterThan0 = "ค่าต้องมากกว่า 0."
    , weDontSellYourDataWeDontShowAdsAndItsFree = "เราไม่ขายข้อมูลของคุณ เราไม่แสดงโฆษณา และบริการนี้ฟรีี"
    , welcomePage = "ยินดีต้อนรับ!"
    , whatDoYouWantPeopleToKnowAboutYou = "คุณต้องการให้ผู้อื่นรู้อะไรเกี่ยวกับคุณบ้าง?"
    , whatSTheNameOfYourGroup = "ชื่อกลุ่มของคุณคืออะไร?"
    , whenDoesItStart = "มันเริ่มเมื่อไหร่?"
    , youCanDoThatHere = "คุณสามารถทำสิ่งนั้นได้ที่นี่."
    , youCanTEditEventsThatHaveAlreadyHappened = "คุณไม่สามารถแก้ไขกิจกรรมที่เกิดขึ้นแล้ว"
    , youCanTEditTheStartTimeOfAnEventThatIsOngoing = "คุณไม่สามารถแก้ไขเวลาเริ่มต้นของกิจกรรมที่กำลังดำเนินอยู่"
    , youHavenTCreatedAnyGroupsYet = "คุณยังไม่ได้สร้างกลุ่มใด ๆ"
    , youNeedToAllowAtLeast2PeopleToJoinTheEvent = "คุณต้องอนุญาตให้ผู้เข้าร่วมกิจกรรมอย่างน้อย 2 คน."
    , yourEmailAddress = "ที่อยู่อีเมลของคุณ"
    , yourName = "ชื่อของคุณ"
    , yourNameCantBeEmpty = "ชื่อของคุณไม่สามารถเว้นว่าง"
    }


diffToStringEnglish : Time.Posix -> Time.Posix -> String
diffToStringEnglish start end =
    let
        difference : Duration
        difference =
            Duration.from start end |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        weeks =
            Duration.inWeeks difference |> floor

        days =
            Duration.inDays difference |> round

        hours =
            Duration.inHours difference |> floor

        minutes =
            Duration.inMinutes difference |> round

        suffix =
            if Time.posixToMillis start <= Time.posixToMillis end then
                ""

            else
                " ago"
    in
    if months >= 2 then
        String.fromInt months ++ "\u{00A0}months" ++ suffix

    else if weeks >= 2 then
        String.fromInt weeks ++ "\u{00A0}weeks" ++ suffix

    else if days > 1 then
        String.fromInt days ++ "\u{00A0}days" ++ suffix

    else if hours > 22 then
        "1\u{00A0}day" ++ suffix

    else if hours > 6 then
        String.fromInt hours ++ "\u{00A0}hours" ++ suffix

    else if Duration.inHours difference >= 1.2 then
        removeTrailing0s 1 (Duration.inHours difference) ++ "\u{00A0}hours" ++ suffix

    else if minutes > 1 then
        String.fromInt minutes ++ "\u{00A0}minutes" ++ suffix

    else
        "1\u{00A0}minute" ++ suffix


diffToStringFrench : Time.Posix -> Time.Posix -> String
diffToStringFrench start end =
    let
        difference : Duration
        difference =
            Duration.from start end |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        weeks =
            Duration.inWeeks difference |> floor

        days =
            Duration.inDays difference |> round

        hours =
            Duration.inHours difference |> floor

        minutes =
            Duration.inMinutes difference |> round
    in
    if months >= 2 then
        String.fromInt months ++ "\u{00A0}mois"

    else if weeks >= 2 then
        String.fromInt weeks ++ "\u{00A0}semaines"

    else if days > 1 then
        String.fromInt days ++ "\u{00A0}jours"

    else if hours > 22 then
        "1\u{00A0}jour"

    else if hours > 6 then
        String.fromInt hours ++ "\u{00A0}heures"

    else if Duration.inHours difference >= 1.2 then
        removeTrailing0s 1 (Duration.inHours difference) ++ "\u{00A0}heures"

    else if minutes > 1 then
        String.fromInt minutes ++ "\u{00A0}minutes"

    else
        "1\u{00A0}minute"


diffToStringSpanish : Time.Posix -> Time.Posix -> String
diffToStringSpanish start end =
    let
        difference : Duration
        difference =
            Duration.from start end |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        weeks =
            Duration.inWeeks difference |> floor

        days =
            Duration.inDays difference |> round

        hours =
            Duration.inHours difference |> floor

        minutes =
            Duration.inMinutes difference |> round
    in
    if months >= 2 then
        String.fromInt months ++ "\u{00A0}meses"

    else if weeks >= 2 then
        String.fromInt weeks ++ "\u{00A0}semanas"

    else if days > 1 then
        String.fromInt days ++ "\u{00A0}días"

    else if hours > 22 then
        "1\u{00A0}día"

    else if hours > 6 then
        String.fromInt hours ++ "\u{00A0}horas"

    else if Duration.inHours difference >= 1.2 then
        removeTrailing0s 1 (Duration.inHours difference) ++ "\u{00A0}horas"

    else if minutes > 1 then
        String.fromInt minutes ++ "\u{00A0}minutos"

    else
        "1\u{00A0}minuto"


diffToStringThai : Time.Posix -> Time.Posix -> String
diffToStringThai start end =
    let
        difference : Duration
        difference =
            Duration.from start end |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        weeks =
            Duration.inWeeks difference |> floor

        days =
            Duration.inDays difference |> round

        hours =
            Duration.inHours difference |> floor

        minutes =
            Duration.inMinutes difference |> round

        suffix =
            if Time.posixToMillis start <= Time.posixToMillis end then
                ""

            else
                " ที่ผ่านมา"
    in
    if months >= 2 then
        String.fromInt months ++ "\u{00A0}เดือน" ++ suffix

    else if weeks >= 2 then
        String.fromInt weeks ++ "\u{00A0}สัปดาห์" ++ suffix

    else if days > 1 then
        String.fromInt days ++ "\u{00A0}วัน" ++ suffix

    else if hours > 22 then
        "1\u{00A0}วัน" ++ suffix

    else if hours > 6 then
        String.fromInt hours ++ "\u{00A0}ชั่วโมง" ++ suffix

    else if Duration.inHours difference >= 1.2 then
        removeTrailing0s 1 (Duration.inHours difference) ++ "\u{00A0}ชั่วโมง" ++ suffix

    else if minutes > 1 then
        String.fromInt minutes ++ "\u{00A0}นาที" ++ suffix

    else
        "1\u{00A0}นาที" ++ suffix
