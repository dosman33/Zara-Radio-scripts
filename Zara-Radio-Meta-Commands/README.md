# Zara-Radio-scripts

Zara Radio Meta Commands
Triggering 3rd party scripts with ZaraRadio
March 2012 

ZaraRadio is a free Windows-based playout software designed to handle small radio station automation duties. We started using it on the Ocho after we got the gas price report script running and needed a way to schedule events to run more regularly than "at the next playlist rotation". Zara can do simple playlists with named and randomized tracks, as well as scheduled events like hourly weather updates and news at noon. We've been able to run a 100% automated radio station using a second linux box to generate text-to-speech updates for weather, news, and the hourly gas price report for our town. So far we've been using a "pull" methodoligy were the Zara playout host downloads updated dynamic content (text-to-speech) from the linux box using batch files and wget for Windows. This works very well for content that only needs to be updated hourly like the gas and weather. The linux box updates the text-to-speech report a few minutes ahead of the playout time, then the Zara host downloads it just before the scheduled playout beings. It's a little bit of a balancing act between ZaraRadio scheduled events, Windows scheduler on the Zara host pulling in the new content, and cron on the linux host - but it works well for us. However this is not a great solution for very frequent updates such as any text-to-speech report that gets updated more frequently than every 10-15 minutes. 

I've wanted to have the system annunciate the names of the songs played for a while but only recently figured out a way to do this. ZaraRadio needs a method to call scripts or otherwise initiate the regeneration of a text-to-speech reports except it does not directly support this. However there's no reason the playout log can't also be used to trigger events, if a script can watch the log it can pick up commands from it too. How do you inject commands though? Simple: add fake song names to your playlist. The song names contain metadata which your script knows how to read. 

Lets say your ZaraRadio playlist.lst file normally looks like this in raw format (open it in Notepad):
```
-1      D:\jingles\station_id_jingles.dir
-1      D:\sid_remixes.dir
-1      D:\sid_remixes.dir
-1      D:\sid_remixes.dir
-1      C:\playlists\random sid remixes.lst
```
In this file, "-1" means to choose a random file from the directory and "sid_remixes.dir" is a directory named "sid_remixes". As long as your tracks are mostly longer than about 1 minute or so you can have the log file searched each minute by a script if you inject meta-commands like this:
```
-1      D:\jingles\station_id_jingles.dir
-1      D:\sid_remixes.dir
-1      D:\sid_remixes.dir
1000    D:\generate_lastzarasongs_4.wav
-1      D:\sid_remixes.dir
1000    C:\station\updated_reports\lastzarasongs.wav
1000    D:\remove_lastzarasongs.wav
-1      C:\playlists\random sid remixes.lst
```
The first column has "-1" to indicate a random track to be played, and "1000" for named tracks to play. This value seems to have no affect on Zara, it's a track time-length value but since these tracks are non-existent or variable in length it doesn't matter what the value is. The time-remaining displayed will be incorrect but that is of minor consequence for this operation. The Zara log file for the 2nd playlist will look like this:
```
...
14:16:27	start	D:\jingles\station_id_jingles\ocho_ident03.wav
14:16:39	start	D:\sid_remixes\RKO-2001 Complete\LMan - Enigma Force (LManic Sunflower Mix).mp3
14:19:32	start	D:\sid_remixes\RKO-2004 Complete\Dafunk - Frozen Minds (Total depression rmx).mp3
14:24:27	start	D:\sid_remixes\RKO-2007 Q2\Hazel - Bruce Lee (Fists Of Fury).mp3
14:28:04	error	The file could not be opened (D:\generate_lastzarasongs_4.wav)
14:28:08	start	D:\sid_remixes\RKO-2001 Complete\Krister Nielsen - Firelord.mp3
14:31:37	start	C:\station\updated_reports\lastzarasongs.wav
14:31:53	error	The file could not be opened (D:\remove_lastzarasongs.wav)
...
```
You will notice two errors, one for each meta-command we issued. Zara skips these tracks without incident but does log them; we use these error messages as commands. I wrote a module for our automated DJ "Sunny" to ftp the log file from the Zara playout host to the linux box each minute, watch for the commands "generate_lastzarasongs_X" and "remove_lastzarasongs", and act accordingly. The command "generate_lastzarasongs_X" tells Sunny to read the names of the last X songs, from most recent to least recent. The reason for issuing this command at track 3 in the "block" is to give the script time to pick up the command, act on it, and place the new "lastzarasongs.wav" file on the Zara box just before it's played. There's a very small race condition where it could pull the log in between the "generate_lastzarasongs_X" command and the 4rth track getting logged, however in the months of running this I've never seen that happen. Also you need to exclude any jingle tracks, error messages, and warning messages (and of course the meta-commands themselves). Here's an example of what the text-to-speech would read: 

"That was Krister Nielsen - Firelord, before that was Hazel - Bruce Lee (Fists Of Fury), before that was Dafunk - Frozen Minds (Total depression rmx), before that was LMan - Enigma Force (LManic Sunflower Mix)". 

So, now the module ftp's the file back up to the Zara playout station. On my ~600MHz Linux box it takes about 6-8 seconds to download the log, generate the report, and upload it back to the Zara box. As long as the last track in the "block" isn't shorter than about a minute this works flawlessly. Because this info is very time sensitive we need to remove this file as soon as it's been played so if something goes wrong a stale lastzarasongs.wav isn't played on the air at the next rotation. It's better to skip it than play incorrect information. In order to do this I cue up removal with the "remove_lastzarasongs" command, the next time the ftp script checks the log it will then remove the file when it sees this. One possible problem is if the linux host dies it could leave a stale lastzarasongs.wav out there, I plan to get a separate script running natively on the Zara playout host to cleanup old files to prevent this from happening. Also while the fourth track is playing the script could try to update lastzarasongs.wav for as many minutes as the track is playing, the script watches for this condition and aborts each time until the cleanup command is issued.
```
14:16:27	start	D:\jingles\station_id_jingles\latest gas prices and weather every hour.wav
14:16:39	start	D:\sid_remixes\RKO-2001 Complete\LMan - Enigma Force (LManic Sunflower Mix).mp3
14:19:32	start	D:\sid_remixes\RKO-2004 Complete\Dafunk - Frozen Minds (Total depression rmx).mp3
14:24:27	start	D:\sid_remixes\RKO-2007 Q2\Hazel - Bruce Lee (Fists Of Fury).mp3
14:28:04	error	The file could not be opened (D:\generate_lastzarasongs_4.wav)
14:28:08	start	D:\sid_remixes\RKO-2001 Complete\Krister Nielsen - Firelord.mp3
14:31:37	start	C:\station\updated_reports\lastzarasongs.wav
14:31:53	error	The file could not be opened (D:\remove_lastzarasongs.wav)
14:31:53	start	D:\jingles\station_id_jingles\stinkocho.wav
14:32:06	start	D:\sid_remixes\RKO-2002 Complete\Rauli - Glider Rider (75686400 beats per year).mp3
14:35:52	start	D:\sid_remixes\RKO-2000 Complete\Linus Walleij - Warez the Phuture (Flying Shark).mp3
14:40:24	start	D:\sid_remixes\RKO-2001 Complete\Slow Poison - Arkanoid Victory (BIT Live Version).mp3
14:43:48	error	The file could not be opened (D:\generate_lastzarasongs_4.wav)
14:43:52	start	D:\sid_remixes\Hazel - Fatal Attraction.mp3
14:48:43	start	C:\station\updated_reports\lastzarasongs.wav
14:49:01	error	The file could not be opened (D:\remove_lastzarasongs.wav)
14:49:01	start	D:\jingles\station_id_jingles\oches latest.wav
14:49:14	start	D:\Kraftwerk\8Bit Operator\Kraftwerk - 12 - Track 12.mp3
14:53:13	start	D:\sid_remixes\RKO-2003 Complete\Gzilla - Last Ninja 2 The Severs.mp3
14:57:01	start	D:\sid_remixes\RKO-2005 Complete\load_error - Gauntlet III (Low Radiation Mix).mp3
15:04:26	start	C:\station\updated_reports\gasreport.mp3
15:10:53	start	C:\station\updated_reports\weather.mp3
15:11:14	error	The file could not be opened (D:\generate_lastzarasongs_4.wav)
15:11:19	start	D:\sid_remixes\RKO-2002 Complete\Trace & Mahoney - Task III (Hum along with the task).mp3
```
And that is how to abuse Zara Radio to control 3rd party scripts for additional automation of your part15 station. 
