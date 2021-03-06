# Zara Report Scripts

# zlog_tally.sh
Counts how many times all played tracks have been played in the current (or previous) month.

When my buddy and I ran a part-15 radio station together we pushed the evelope on what could be done around Zara Radio. We were lazy and relied on mostly randomized playlists generated by Zara Radio itself. At one point I realized it would be good to see just how much re-play our music archive was getting and so I wrote a simple unix shell script to tally up this data based on the Zara Radio play log. We thought we had enough music on the system to go months without repeats, but to our surprise everything we had was getting repeated as much as 7 times a month. That wasn't really a problem, but did clue us in to how often tracks were getting re-played. It also showed us that Zara's idea of random in this sense was very reasonable as it actively tried to not play the same tracks too often (which is probably not truely random, but in this case that was fine).



```
1680AM The Ocho! track tally for 2012-10
------------------------------------------------------------------------------------
      7 D:\other\messyman-OVERDOSE.mp3
      7 D:\other\Digital_Motion-Quest__Basement_Mix_.mp3
      7 D:\other\Digital_Motion-Adriana__Big_Time_Beat_Mix_.mp3
      7 D:\other\Audiomoe-Persistence.mp3
      7 D:\other\Audiomoe-57_Spring.mp3
      6 D:\other\Dr Steel - Fibonacci.mp3
      6 D:\other\Dr Steel - Back and Forth.mp3
      6 D:\other\Digital_Motion-The_Facts_of_Life.mp3
      6 D:\other\Digital_Motion-Radium.mp3
```


--------------------

# zlog_exceptions.sh
Sorts Zara log files and give counts on non-file play events.

This provides some very basic info on Zara Radio exceptions which is more useful if you are abusing it by inserting what I refer to as "meta commands" into the playlist. More info on this topic here:
https://github.com/dosman33/Zara-Radio-scripts/tree/master/Zara-Radio-Meta-Commands
