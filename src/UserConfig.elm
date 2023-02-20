module UserConfig exposing (..)

import Colors exposing (fromHex)
import Element exposing (Color)


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
    { welcomePage : String
    , title : String
    , daysUntilEvent : Int -> String
    , theLinkYouUsedIsEitherInvalidOrHasExpired : String
    , goToHomepage : String
    , twoPeopleOnAVideoConference : String
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests : String
    , weDontSellYourDataWeDontShowAdsAndItsFree : String
    , readMore : String
    , groupNotFound : String
    , userNotFound : String
    , codeOfConduct : String
    , theMostImportantRuleIs : String
    , dontBeAJerk : String
    , codeOfConduct1 : String
    , codeOfConduct2 : String
    , codeOfConduct3 : String
    , codeOfConduct4 : String
    , codeOfConduct5 : String
    , moderationHelpRequest : String
    , frequentQuestions : String
    , faqQuestion1 : String
    , isItI : String
    , creditGoesTo : String
    , forHelpingMeOutWithPartsOfTheApp : String
    , faqQuestion2 : String
    , faq1 : String
    , faq2 : String
    , faqQuestion3 : String
    , faq3 : String
    }


englishTexts : Texts
englishTexts =
    { welcomePage = "Welcome to the event!"
    , title = "Event"
    , daysUntilEvent = \days -> "Days until event: " ++ String.fromInt days
    , theLinkYouUsedIsEitherInvalidOrHasExpired = "The link you used is either invalid or has expired."
    , goToHomepage = "Go to homepage"
    , twoPeopleOnAVideoConference = "Two people on a video conference"
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests = "A place to join groups of people with shared interests"
    , weDontSellYourDataWeDontShowAdsAndItsFree = "We don't sell your data, we don't show ads, and it's free."
    , readMore = "Read more"
    , groupNotFound = "Group not found"
    , userNotFound = "User not found"
    , codeOfConduct = "Code of Conduct"
    , theMostImportantRuleIs = "The most important rule is"
    , dontBeAJerk = "don't be a jerk"
    , codeOfConduct1 = "Here is some guidance in order to fulfill the \"don't be a jerk\" rule:"
    , codeOfConduct2 = "• Respect people regardless of their race, gender, sexual identity, nationality, appearance, or related characteristics."
    , codeOfConduct3 = "• Be respectful to the group organizers. They put in the time to coordinate an event and they are willing to invite strangers. Don't betray their trust in you!"
    , codeOfConduct4 = "• To group organizers: Make people feel included. It's hard for people to participate if they feel like an outsider."
    , codeOfConduct5 = "• If someone is being a jerk that is not an excuse to be a jerk back. Ask them to stop, and if that doesn't work, avoid them and explain the problem here "
    , moderationHelpRequest = "Moderation help request"
    , frequentQuestions = "Frequently asked questions"
    , faqQuestion1 = "Who is behind all this?"
    , isItI = "It is I, "
    , creditGoesTo = ". Credit goes to "
    , forHelpingMeOutWithPartsOfTheApp = " for helping me out with parts of the app."
    , faqQuestion2 = "Why was this website made?"
    , faq1 = "I dislike that meetup.com charges money, spams me with emails, and feels bloated. Also I wanted to try making something more substantial using "
    , faq2 = " to see if it's feasible to use at work."
    , faqQuestion3 = "If this website is free and doesn't run ads or sell data, how does it sustain itself?"
    , faq3 = "I just spend my own money to host it. That's okay because it's designed to cost very little to run. In the unlikely event that Meetdown gets very popular and hosting costs become too expensive, I'll ask for donations."
    }


frenchTexts : Texts
frenchTexts =
    { welcomePage = "Bienvenue à l'événement!"
    , title = "Événement"
    , daysUntilEvent = \days -> "Jours jusqu'à l'événement: " ++ String.fromInt days
    , theLinkYouUsedIsEitherInvalidOrHasExpired = "Le lien que vous avez utilisé est invalide ou a expiré."
    , goToHomepage = "Aller à la page d'accueil"
    , twoPeopleOnAVideoConference = "Deux personnes sur une vidéoconférence"
    , aPlaceToJoinGroupsOfPeopleWithSharedInterests = "Un endroit pour rejoindre des groupes de personnes partageant des centres d'intérêt"
    , weDontSellYourDataWeDontShowAdsAndItsFree = "Nous ne vendons pas vos données, nous ne montrons pas de publicités et c'est gratuit."
    , readMore = "En savoir plus"
    , groupNotFound = "Groupe introuvable"
    , userNotFound = "Utilisateur introuvable"
    , codeOfConduct = "Code de conduite"
    , theMostImportantRuleIs = "La règle la plus importante est"
    , dontBeAJerk = "ne sois pas un.e imbécile"
    , codeOfConduct1 = "Voici quelques conseils pour respecter la règle \"ne sois pas un.e imbécile\":"
    , codeOfConduct2 = "• Respecte les personnes indépendamment de leur race, de leur sexe, de leur identité sexuelle, de leur nationalité, de leur apparence ou de toute autre caractéristique connexe."
    , codeOfConduct3 = "• Sois respectueux envers les organisateurs de groupes. Ils consacrent du temps à coordonner un événement et ils sont prêts à inviter des gens qu'ils ne connaissent pas. Ne trahis pas leur confiance en toi!"
    , codeOfConduct4 = "• Pour les organisateurs de groupes: Faites en sorte que les gens se sentent inclus. Il est difficile pour les gens de participer si ils se sentent comme des étrangers."
    , codeOfConduct5 = "• Si quelqu'un est un imbécile, ce n'est pas une excuse pour être un imbécile en retour. Demande-leur de s'arrêter, et si cela ne fonctionne pas, évite-les et explique le problème ici "
    , moderationHelpRequest = "Demande d'aide pour la modération"
    , frequentQuestions = "Questions fréquentes"
    , faqQuestion1 = "Qui est derrière tout ça ?"
    , isItI = "C'est moi, "
    , creditGoesTo = ". Merci à "
    , forHelpingMeOutWithPartsOfTheApp = " pour m'avoir aidé avec certaines parties de l'application."
    , faqQuestion2 = "Pourquoi avoir créé ce site web ?"
    , faq1 = "Je n'aime pas que meetup.com soit payant, m'envoie des emails de spam et soit trop lourd. J'ai aussi voulu essayer de faire quelque chose de plus substantiel en utilisant "
    , faq2 = " pour voir si c'est faisable de l'utiliser au travail."
    , faqQuestion3 = "Si ce site web est gratuit et ne vend pas vos données, comment fait-il pour se financer ?"
    , faq3 = "Je dépense mon propre argent pour l'héberger. C'est ok car il est conçu pour coûter très peu à faire tourner. Dans le cas improbable où Meetdown deviendrait très populaire et que les coûts d'hébergement deviennent trop élevés, je demanderai des dons."
    }
