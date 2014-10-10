#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "Chrome.h"

ChromeTab *getFirstVkTab(ChromeApplication *app) {
  for (ChromeWindow *window in [[app windows] get]) {
    for (ChromeTab *tab in [[window tabs] get]) {
      if ([[tab URL] hasPrefix:@"https://vk.com/"] || [[tab URL] hasPrefix:@"http://vk.com/"]) {
        return tab;
      }
    }
  }
  return nil;
}

NSDictionary *getCurrentSongStatus(ChromeTab *tab) {
  return [tab executeJavascript:@"(function(){ var s = audioPlayer.lastSong; s.curTime = ''+audioPlayer.curTime; s['3'] = ''+s['3']; return s; })();"];
}

void executeNext(ChromeTab *tab) {
  [tab executeJavascript:@"(function(){ return audioPlayer.nextTrack(); })();"];
}

void executePrevious(ChromeTab *tab) {
  [tab executeJavascript:@"(function(){ return audioPlayer.prevTrack(); })();"];
}

void executePlayPause(ChromeTab *tab) {
  [tab executeJavascript:@"(function(){ return audioPlayer.player.paused() ? audioPlayer.playTrack() : audioPlayer.pauseTrack(); })();"];
}

void usage(char *cmd) {
  printf("Usage: %s <command>\n\n  Commands:\n", cmd);
  printf("    %-28s\n      %s\n", "status|st",                  "Show status and track information");
  printf("    %-28s\n      %s\n", "play|pause|playpause|pp",    "Toggle the playing/paused state of the current track");
  printf("    %-28s\n      %s\n", "next|n",                     "Advance to the next track in the current playlist");
  printf("    %-28s\n      %s\n", "prev|p",                     "Return to the previous track in the current playlist");
}

int main(int argc, char *argv[]) {
  ChromeApplication *app = [SBApplication applicationWithBundleIdentifier:@"com.google.Chrome"];

  int cmdFound = 0;

  ChromeTab *tab = getFirstVkTab(app);

  if (tab == nil) {
    printf("Can't find a VK tab\n");
    return 1;
  }

  if (argc == 2) {
    if (strcmp(argv[1], "play") == 0 || strcmp(argv[1], "pause") == 0 || strcmp(argv[1], "playpause") == 0 || strcmp(argv[1], "pp") == 0) {
      executePlayPause(tab);
      cmdFound = 1;
    } else if (strcmp(argv[1], "next") == 0 || strcmp(argv[1], "n") == 0) {
      executeNext(tab);
      cmdFound = 1;
    } else if (strcmp(argv[1], "prev") == 0 || strcmp(argv[1], "p") == 0) {
      executePrevious(tab);
      cmdFound = 1;
    } else if (strcmp(argv[1], "status") == 0 || strcmp(argv[1], "st") == 0) {
      // NSDictionary *song = getCurrentSongStatus(tab);
      // if (!song) {
      //   return 0;
      // }
      // NSString *status = [song objectForKey:@"status"];
      // if (status == nil) {
      //   return 0;
      // }
      // printf("VK is %s\n", [status UTF8String]);
      // song = [song objectForKey:@"song"];
      // if (!song) {
      //   return 0;
      // }
      // if ([status isEqualToString:@"playing"] || [status isEqualToString:@"paused"] || [status isEqualToString:@"loading"]) {
      //   printf("Current track: %s - %s [%.2f of %.2f seconds]\n", [[[song objectForKey:@"artistName"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] UTF8String], [[[song objectForKey:@"songName"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] UTF8String], [[song objectForKey:@"position"] floatValue]/1000, [[song objectForKey:@"calculatedDuration"] floatValue]/1000);
      // }
      NSDictionary *song = getCurrentSongStatus(tab);
      if (!song) {
        return 1;
      }
      NSString *artist = [[song objectForKey:@"5"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      NSString *title = [[song objectForKey:@"6"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      NSString *position = [song objectForKey:@"curTime"];
      NSString *duration = [song objectForKey:@"3"];
      if (!artist || !title || !position || !duration) {
        return 1;
      }
      printf("Current track: %s - %s [%s of %s seconds]\n", [artist UTF8String], [title UTF8String], [position UTF8String], [duration UTF8String]);
      cmdFound = 1;
    } else if (strcmp(argv[1], "help") == 0 || strcmp(argv[1], "h") == 0) {
      usage(argv[0]);
      return 0;
    }
  }

  if (!cmdFound) {
    usage(argv[0]);
    return 1;
  }

  return 0;
}
