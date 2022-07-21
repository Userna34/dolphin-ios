// Copyright 2022 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#import "MappingRootViewController.h"

#import <map>
#import <string>

#import "Core/HW/GCPad.h"
#import "Core/HW/GCPadEmu.h"
#import "Core/HW/Wiimote.h"
#import "Core/HW/WiimoteEmu/Extension/Classic.h"
#import "Core/HW/WiimoteEmu/Extension/DrawsomeTablet.h"
#import "Core/HW/WiimoteEmu/Extension/Drums.h"
#import "Core/HW/WiimoteEmu/Extension/Guitar.h"
#import "Core/HW/WiimoteEmu/Extension/Nunchuk.h"
#import "Core/HW/WiimoteEmu/Extension/TaTaCon.h"
#import "Core/HW/WiimoteEmu/Extension/Turntable.h"
#import "Core/HW/WiimoteEmu/Extension/UDrawTablet.h"
#import "Core/HW/WiimoteEmu/WiimoteEmu.h"

#import "InputCommon/ControllerEmu/ControlGroup/Attachments.h"
#import "InputCommon/ControllerEmu/ControllerEmu.h"
#import "InputCommon/InputConfig.h"

#import "FoundationStringUtil.h"
#import "LocalizationUtil.h"
#import "MappingDeviceViewController.h"
#import "MappingRootDeviceCell.h"
#import "MappingRootExtensionCell.h"
#import "MappingRootGroupCell.h"
#import "MappingUtil.h"

struct Group {
  std::string name;
  ControllerEmu::ControlGroup* controlGroup;
};

struct Section {
  std::string headerName;
  std::string footerName;
  std::vector<Group> groups;
};

@interface MappingRootViewController ()

@end

@implementation MappingRootViewController {
  InputConfig* _config;
  ControllerEmu::EmulatedController* _controller;
  std::vector<Section> _sections;
}

- (void)viewDidLoad {
  if (self.mappingType == DOLMappingTypePad) {
    _config = Pad::GetConfig();
  } else if (self.mappingType == DOLMappingTypeWiimote) {
    _config = Wiimote::GetConfig();
  }
  
  _controller = _config->GetController(self.mappingPort);
}

- (void)viewWillAppear:(BOOL)animated {
  _sections.clear();
  
  switch (self.mappingType) {
    case DOLMappingTypePad: {
      _sections.push_back({"General and Options", "", {
        {"Buttons", Pad::GetGroup(self.mappingPort, PadGroup::Buttons)},
        {"D-Pad", Pad::GetGroup(self.mappingPort, PadGroup::DPad)},
        {"Control Stick", Pad::GetGroup(self.mappingPort, PadGroup::MainStick)},
        {"C Stick", Pad::GetGroup(self.mappingPort, PadGroup::CStick)},
        {"Triggers", Pad::GetGroup(self.mappingPort, PadGroup::Triggers)},
        {"Rumble", Pad::GetGroup(self.mappingPort, PadGroup::Rumble)},
        {"Options", Pad::GetGroup(self.mappingPort, PadGroup::Options)}
      }});
      
      break;
    }
    case DOLMappingTypeWiimote: {
      ControllerEmu::ControlGroup* extension_group = Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Attachments);
      
      _sections.push_back({"General and Options", "", {
        {"Buttons", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Buttons)},
        {"D-Pad", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::DPad)},
        {"Hotkeys", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Hotkeys)},
        {"Extension", extension_group},
        {"Rumble", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Rumble)},
        {"Options", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Options)}
      }});
      
      _sections.push_back({"Motion Simulation", "", {
        {"Shake", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Shake)},
        {"Point", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Point)},
        {"Tilt", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Tilt)},
        {"Swing", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::Swing)}
      }});
      
      std::string wiimoteMotionHelp = "WARNING: The controls under Accelerometer and Gyroscope are designed to "
                                      "interface directly with motion sensor hardware. They are not intended for "
                                      "mapping traditional buttons, triggers or axes. You might need to configure "
                                      "alternate input sources before using these controls.";
      
      _sections.push_back({"Motion Input", wiimoteMotionHelp, {
        {"Point", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::IMUPoint)},
        {"Accelerometer", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::IMUAccelerometer)},
        {"Gyroscope", Wiimote::GetWiimoteGroup(self.mappingPort, WiimoteEmu::WiimoteGroup::IMUGyroscope)}
      }});
      
      ControllerEmu::Attachments* ce_extension = static_cast<ControllerEmu::Attachments*>(extension_group);
      WiimoteEmu::ExtensionNumber extension = static_cast<WiimoteEmu::ExtensionNumber>(ce_extension->GetSelectionSetting().GetValue());
      
      switch (extension) {
        case WiimoteEmu::ExtensionNumber::NUNCHUK: {
          _sections.push_back({"Nunchuk", "", {
            {"Stick", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Stick)},
            {"Buttons", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Buttons)}
          }});
          
          _sections.push_back({"Extension Motion Simulation", "", {
            {"Shake", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Shake)},
            {"Tilt", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Tilt)},
            {"Swing", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::Swing)}
          }});
          
          std::string extensionMotionHelp = "WARNING: These controls are designed to interface directly with motion "
                                            "sensor hardware. They are not intended for mapping traditional buttons, triggers or "
                                            "axes. You might need to configure alternate input sources before using these controls.";
          
          _sections.push_back({"Extension Motion Input", extensionMotionHelp, {
            {"Accelerometer", Wiimote::GetNunchukGroup(self.mappingPort, WiimoteEmu::NunchukGroup::IMUAccelerometer)}
          }});
          
          break;
        }
        case WiimoteEmu::ExtensionNumber::CLASSIC:
          _sections.push_back({"Classic Controller", "", {
            {"Buttons", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::Buttons)},
            {"D-Pad", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::DPad)},
            {"Left Stick", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::LeftStick)},
            {"Right Stick", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::RightStick)},
            {"Triggers", Wiimote::GetClassicGroup(self.mappingPort, WiimoteEmu::ClassicGroup::Triggers)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::GUITAR:
          _sections.push_back({"Guitar", "", {
            {"Stick", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Stick)},
            {"Strum", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Strum)},
            {"Frets", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Frets)},
            {"Buttons", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Buttons)},
            {"Whammy", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::Whammy)},
            {"Slider Bar", Wiimote::GetGuitarGroup(self.mappingPort, WiimoteEmu::GuitarGroup::SliderBar)},
          }});
          break;
        case WiimoteEmu::ExtensionNumber::DRUMS:
          _sections.push_back({"Drum Kit", "", {
            {"Stick", Wiimote::GetDrumsGroup(self.mappingPort, WiimoteEmu::DrumsGroup::Stick)},
            {"Pads", Wiimote::GetDrumsGroup(self.mappingPort, WiimoteEmu::DrumsGroup::Pads)},
            {"Buttons", Wiimote::GetDrumsGroup(self.mappingPort, WiimoteEmu::DrumsGroup::Buttons)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::TURNTABLE:
          _sections.push_back({"DJ Turntable", "", {
            {"Stick", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::Stick)},
            {"Buttons", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::Buttons)},
            {"Effect", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::EffectDial)},
            {"Left Table", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::LeftTable)},
            {"Right Table", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::RightTable)},
            {"Crossfade", Wiimote::GetTurntableGroup(self.mappingPort, WiimoteEmu::TurntableGroup::Crossfade)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::UDRAW_TABLET:
          _sections.push_back({"uDraw GameTablet", "", {
            {"Buttons", Wiimote::GetUDrawTabletGroup(self.mappingPort, WiimoteEmu::UDrawTabletGroup::Buttons)},
            {"Stylus", Wiimote::GetUDrawTabletGroup(self.mappingPort, WiimoteEmu::UDrawTabletGroup::Stylus)},
            {"Touch", Wiimote::GetUDrawTabletGroup(self.mappingPort, WiimoteEmu::UDrawTabletGroup::Touch)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::DRAWSOME_TABLET:
          _sections.push_back({"Drawsome Tablet", "", {
            {"Stylus", Wiimote::GetDrawsomeTabletGroup(self.mappingPort, WiimoteEmu::DrawsomeTabletGroup::Stylus)},
            {"Touch", Wiimote::GetDrawsomeTabletGroup(self.mappingPort, WiimoteEmu::DrawsomeTabletGroup::Touch)}
          }});
          break;
        case WiimoteEmu::ExtensionNumber::TATACON:
          _sections.push_back({"Taiko Drum", "", {
            {"Center", Wiimote::GetTaTaConGroup(self.mappingPort, WiimoteEmu::TaTaConGroup::Center)},
            {"Rim", Wiimote::GetTaTaConGroup(self.mappingPort, WiimoteEmu::TaTaConGroup::Rim)}
          }});
          break;
        default:
          break;
      }
      
      break;
    }
  }
  
  [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
  return _sections.size() + 1; // Device section is always present
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0: // Devices
      return 1;
    default:
      return _sections[section - 1].groups.size();
  }
}

- (NSString *)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
  NSInteger actualSection = section - 1;
  
  if (actualSection < 0) {
    return @"";
  }
  
  NSString* sectionLocalizable = CppToFoundationString(_sections[actualSection].headerName);
  return DOLCoreLocalizedString(sectionLocalizable);
}

- (NSString *)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section {
  NSInteger actualSection = section - 1;
  
  if (actualSection < 0) {
    return @"";
  }
  
  NSString* sectionLocalizable = CppToFoundationString(_sections[actualSection].footerName);
  return DOLCoreLocalizedString(sectionLocalizable);
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    MappingRootDeviceCell* deviceCell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
    
    const auto deviceString = _controller->GetDefaultDevice().ToString();
    if (!deviceString.empty()) {
      deviceCell.deviceLabel.text = CppToFoundationString(deviceString);
    } else {
      // Show at least *something* to make it clear that no device is selected.
      deviceCell.deviceLabel.text = @"—";
    }
    
    return deviceCell;
  }
  
  NSInteger actualSection = indexPath.section - 1;
  
  const auto& group = _sections[actualSection].groups[indexPath.row];
  
  auto attachments = dynamic_cast<ControllerEmu::Attachments*>(group.controlGroup);
  if (attachments) {
    MappingRootExtensionCell* extensionCell = [tableView dequeueReusableCellWithIdentifier:@"ExtensionSelectCell" forIndexPath:indexPath];
    extensionCell.extensionLabel.text = [MappingUtil getLocalizedStringForWiimoteExtension:static_cast<WiimoteEmu::ExtensionNumber>(attachments->GetSelectedAttachment())];
    
    return extensionCell;
  }
  
  MappingRootGroupCell* groupCell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell" forIndexPath:indexPath];
  groupCell.nameCell.text = DOLCoreLocalizedString(CppToFoundationString(group.name));
  
  return groupCell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"toDevice"]) {
    MappingDeviceViewController* deviceController = segue.destinationViewController;
    
    deviceController.emulatedController = _controller;
  }
}

@end
