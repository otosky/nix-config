{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.extraConfig."bluetooth-source-priority" = {
      "monitor.bluez.rules" = [
        {
          matches = [{"node.name" = "~bluez_input.*";}];
          actions.update-props = {
            "priority.session" = 2000;
          };
        }
      ];
    };
  };
}
