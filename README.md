Don't use this...

# InvestscreenshotAI
Takes a screenshot of the screen with an investment chart and tells you if you should buy, sell, or hold using OpenAI's new really cheap GPT-5-Nano model.

# Disclaimers
- Ai is shockingly bad at investing suprisingly so don't use this.
- I don't know swift so most of this code was written by chatgpt and copilot.
- I don't understand apple apps so it's bad and why there is no .env file it is just embedded in the code.
- It was originally in nodejs but that doesnt let you listen for keystrokes on mac silicon devices so had to resort to this.
- I don't know if there is a way to proper easily distribute it, feel free to make a pull request.
- When you build DO NOT SHARE IT. Even the bundled .app file will include your OpenAI, api key so don't do that.

# Build
IDK but i think just downloading my xcode project wont work, so make it yourself is better. So take my main.swift file and stick it in your main app dir and delete the other stuff and that popup that appears just say yes adjust headers or whatever the blue button is. Then add your open AI api key into the place in that file, it's clear where it should go. Just put like $5 into open AI, if you were to only use this then it would still be hardly anything, you could probably run it a few thousand times before you even use a $1 worth of credit even with the low quality image used in the screenshot. Then you need to go in the app settings to target -> signing and capabilities -> network outgoing (client) then enable that. Then build, then archive -> custom -> copy -> then anywhere is fine but note you cannot move it manually afterwards you have to re-build it - idk why but the permissions break so networking doesn't work. Go to mac settings -> privacy and security -> accessibility -> + then the app file and then add that. Do the same in mac settings -> privacy and security -> Screen & System Audio Recording (i think it does that automatically idk).  Then you can just run it. Bingo. Easy.

# Run
Start the app and press z to trigger it. You cannot move it from where it was saved without casuing issies for some reason idk why.
