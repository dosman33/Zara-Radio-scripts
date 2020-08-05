# Zara-Radio-scripts


# evtdump.sh - Decoder For Zara Radio Event Backup Files

Zara Radio is a piece of free Windows based playout software intended for part15 and other small radio stations. It has a reasonable event scheduler which makes automation easier. The active event schedule is kept in the Windows Registry, however backups can be made which also allow you to export your schedule to other systems. This backup file is in binary format but easy enough to decode. I wrote a shell script which can decode the event file backup and output either text or html. If multiple people make changes to the stations event schedule then this can be an easy way for them to see updates while away from the station. This can also be used for posting your event schedule on a website for the public to view. 

Example of two records in an event file backup:

0000000: 4556 5430 3300 0002 0000 0001 0101 0101  EVT03...........
0000010: 0101 2800 0000 433a 5c73 7461 7469 6f6e  ..(...C:\station
0000020: 5c75 7064 6174 6564 5f72 6570 6f72 7473  \updated_reports
0000030: 5c67 6173 7265 706f 7274 2e6d 7033 1100  \gasreport.mp3..
0000040: 0000 3039 2f31 352f 3037 2031 353a 3030  ..09/15/07 15:00
0000050: 3a30 3011 0000 0030 392f 3135 2f30 3720  :00....09/15/07
0000060: 3135 3a34 373a 3138 0001 0000 00ff eefd  15:47:18........
0000070: 0000 0a00 0000 0002 0000 0001 0101 0101  ................
0000080: 0101 2600 0000 433a 5c73 7461 7469 6f6e  ..&...C:\station
0000090: 5c75 7064 6174 6564 5f72 6570 6f72 7473  \updated_reports
00000a0: 5c77 6561 7468 6572 2e6d 7033 1100 0000  \weather.mp3....
00000b0: 3039 2f31 352f 3037 2031 353a 3030 3a30  09/15/07 15:00:0
00000c0: 3111 0000 0030 392f 3135 2f30 3720 3135  1....09/15/07 15
00000d0: 3a34 383a 3436 0001 0000 00ff eefd 0000  :48:46..........
00000e0: 0a00 0000 0002 0000 0001 0101 0101 0101  ................

The script documents most of what each field represents, for futher details you should just check out the script. 
