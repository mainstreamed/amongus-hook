local supportedGames    = {}

supportedGames.FALLEN = {

      placeIDs          = { 13800717766; 15479377118; 16849012343; };
      gitPath           = 'fallensurvival';

      gameName          = 'Fallen Survival';
      status            = 'Undetected';
      executors         = { 'Wave'; 'Swift'; 'Volt'; 'Seliware'; };
      customMessage     = {
            ['Potassium']     = 'Use at own risk';
            ['Volcano']       = 'Use at own risk';
      };
};
supportedGames.TRIDENT = {

      placeIDs          = { 13253735473; };
      gitPath           = 'tridentsurvival';

      gameName          = 'Trident Survival';
      status            = 'Undetected';
      executors         = { 'Wave'; 'Swift'; 'Velocity'; 'Potassium'; 'Seliware'; 'Volcano'; 'Volt'; };
      customMessage     = {

            ['executor']      = 'custom message';
      };
};
supportedGames.LONE = {

      placeIDs          = { 13800223141; 139307005148921; };
      gitPath           = 'lonesurvival';

      gameName          = 'Lone Survival';
      status            = 'Undetected';
      executors         = { 'Wave'; 'Swift'; 'Velocity'; 'Potassium'; 'Seliware'; 'Volcano'; 'Volt'; };
      customMessage     = {

            ['executor']      = 'custom message';
      };
};

-- WAVE HOTFIX
if (type(getgenv) == 'function' and getgenv().setfflag == nil) then
      getgenv().setfflag = function() end;
end;

return supportedGames;
