Karma
-----

Originally created by Aveasau
Resurrected by Endareth
Kept alive by Kärbär from EU-Proudmoore (currently mostly playing my alt on EU-Elune...)

Installation
------------
Just unzip into your <WoW-Directory>\Interface\AddOns folder, like every other AddOn out there...

Changes
-------
This is merely a tiny update for three reasons:
(At least that was true for the time when I wrote this readme.txt...)
First, (just my personal opinion here) I dislike what ui.worldofwar.net has become. (I lost my login because ui.worldofwar.net completely messed up logins with non-Ascii characters.) So, I won't update there anymore.
Second, noone is currently updating Karma at all (to my knowledge) which makes it look as if it's dead.
Third, I am still playing with it, fixing tiny problems here, adding tiny features there, e.g. a (very) minimal French localization. :)

Main fix: It should not anymore fall in the traps that simpleMinimap adds.
Features: Mainly just some polishing here and there, you'll notice only if you know Karma already.

Plans (slightly updated 20080528)
---------------------------------
Short term:
Quest tracking should not log dailies, at least that should be configurable.
It should be configurable to disable Time/Zone tracking when in a Raid group.

Medium term: :D
Quest tracking should (also) not log progress for the group members which are out of range since some time (say, a minute - probably configurable).
Karma unnecessarily pollutes too much of the global namespace.
I'd like to local-ify a lot more functions.
Actually, with the collision that NiKarma introduced blissfully, I'd like to move all externally visible functions into an object.
That would be a nice way to keep the namespace clean. :)

Long term:
I'd like a way to share Karma values.
That also requires that Karma has more than one value (social Karma, skill Karma, other that I forgot ;)) and that the indirect Karma is somewhere logged with source to allow regular sharing.
This is still very much in the pondering area of things. ;)
(Probably a second AddOn to enable for sharing, to allow the share-information to be outside of the regular database.)

Veery long term:
I'd like to split it up into multiple parts, especially moving quest tracking into a dependant AddOn one can deactivate.
(My current DB is ~10MB, as it contains a large amount of quest tracking and that in two languages...)
But I'd like to redesign many pieces first, so you'll probably not see anything big happening on the front side soon.

Final words
-----------
The code of simpleMinimap is incredibly idio^Hshortsighted. That's all.
