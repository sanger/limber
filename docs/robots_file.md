<!--
# @markup markdown
# @title Robots file
-->

# Bed verifications background
The robots configuration file defines all the bed verifications in Limber.

A bed verification is a check done by the lab staff when loading a liquid handler robot. The idea is to check both that the plates are on the correct beds (plate locations) on the deck of the robot, and if pairing them that those plates have the expected parent and child relationship in the LIMS (that you've not muddled up pairings of plates).
The goal is to reduce human error when loading liquid handler robots, preventing mistakes and plate swaps. This is critical in high throughput pipelines especially, where many plates are being processed simultaneously in repetitive tasks.

There will be a location barcode stuck on or near each bed on the liquid handler deck. The user scans both this bed barcode and the labware barcode, and the system validates that the labware is of the correct purpose and is in the correct deck location. Clicking on 'validate' then checks the labwares are correctly related to one another.

A successful bed verification typically happens in 2 stages; validation, then transfers of samples to the child.

The use of the bed verification is also logged as an event to the MLWH.

Remember to include any bed verifications in your Integration Suite tests. They are an important part of pipeline development and vital to prevent mistakes in the labs.

NB. Liquid handler robots are mostly for transfers between plates. Transfers involving tubes are less likely to be automated in this way (tubes are difficult for automation to deal with, primarily due to their screw cap lids and small size).

# Bed and Robot barcodes
Beds and Robots are barcode labelled.
The numbers that you see in the bed configurations translate to bed barcodes.
The robot barcodes can be any text (it should be unique), or if a barcode number is used that relates to the id for the robot in the Sequencescape database (not all robots are set up in Sequencescape).

The Automation team are responsible for printing and applying robot and bed barcode labels to the liquid handler robots in the labs.

In a Rails Console you can translate the bed numbers to bed barcodes or robot ids to robot barcodes using the Sanger Barcode Format gem, see:
```code
gem 'sanger_barcode_format', github: 'sanger/sanger_barcode_format'
```

## Robot barcodes
For robot barcodes the number is the robot id in Sequencescape. It should be unique for each robot.

The barcode can be generated at the command line using the Sanger Barcode Format gem:
e.g.
```code
SBCF::SangerBarcode.new(prefix:'RB', number:1).machine_barcode

-> 4880000001780
```

Note that not all robots are defined in Sequencescape and have ids. They can print a robot label containing any string they like. Some of the liquid handler robots are named and labeled in a more human friendly manner that makes sense to them.

## Bed barcodes
For barcodes of robot beds the beds are numbered incrememtly for each robot.
i.e. Many robots share the same bed numbers, and the same bed barcodes, they are not unique between robots.

The barcode can again be generated at the command line using the Sanger Barcode Format gem:
e.g.
```code
SBCF::SangerBarcode.new(prefix:'BD', number:1).machine_barcode

-> 580000001806
```

Table of first 20 bed numbers and their barcodes for reference:
```code
1   580000001806
2   580000002810
3   580000003824
4   580000004838
5   580000005842
6   580000006856
7   580000007860
8   580000008874
9   580000009659
10  580000010815
11  580000011829
12  580000012833
13  580000013847
14  580000014851
15  580000015865
16  580000016879
17  580000017654
18  580000018668
19  580000019672
20  580000020838
```

# Simple and Bravo robots
For a simple one to one transfer you can use a simple_robot or bravo_robot configuration (Bravo is a specific liquid handler robot model they use in the Sanger Labs).

These validate a single 'passed' source plate and a single 'pending' destination, and transition the destination plate to 'passed'.

Set the relevant labware purpose keys for the step, and the bed numbers supplied by the lab automation team or lab staff.

Both simple and bravo robots can transition to 'started' state with an optional argument.

## Simple robot
```code
simple_robot do
  from 'LB Cap Lib PCR', bed(1)
  to 'LB Cap Lib PCR-XP', bed(9)
end
```

Or with optional name as the first parameter and / or a 'transition_to' argument to set alternate final destination state:
```code
simple_robot('mosquito', transition_to: 'started') do
```

## Bravo robot
```code
bravo_robot do
  from 'LB Cherrypick', bed(7)
  to 'LB Shear', bed(9)
end
```

Or with optional 'transition_to' argument:
```code
bravo_robot transition_to: 'started' do
```

# Custom robots
Custom robot configuration gives you full control and flexibility over beds and states. These robots can include any number of beds. Some liquid handler robots process multiple pairs of plates in parallel e.g. A->B x 4. Others process several sequential steps in one method e.g. A->B->C.

## Custom one to one transfer between two labwares
In this simple example the robot does a simple one to one transfer.

Example for a Zephyr liquid handler robot:
```code
custom_robot(
  'zephyr-lib-pcr-purification',
  name: 'Zephyr LB Lib PCR => LB Lib PCR XP',
  verify_robot: false,
  beds: {
    bed(2).barcode => {
      purpose: 'LB Lib PCR',
      states: ['passed'],
      label: 'Bed 2'
    },
    bed(7).barcode => {
      purpose: 'LB Lib PCR-XP',
      states: ['pending'],
      label: 'Bed 7',
      parent: bed(2).barcode,
      target_state: 'passed'
    }
  }
)
```

### Parameters
`name:`
This is the name that will appear on the button in the Limber view

`require_robot: true`
The user will be required to scan an identifying barcode on the liquid handler robot.

`verify_robot: true`
The user will be required to scan an identifying barcode on the liquid handler robot, and the system will verify that the same robot barcode was scanned as in the previous bed verification. This can be used to chain a sequence of bed verifications and ensure the same plates are used on the same liquid handler robot. Useful when a plate leaves the liquid handler deck for some purpose (e.g. PCR) and then returns for the next step. NB. This can block the user continuing if they entered a spurious string for the first bed verification that they cannot remember for the second. There is currently no way to validate the scanned robot barcode against anything, any string is accepted.

`beds:`
Hash of bed definitions for this bed verification.

`bed:`
Each bed definition is keyed on a bed barcode e.g. bed(2).barcode.

Within each bed:
  `purpose:`
  The purpose key (or keys) that are valid labwares for this bed. If the labware is not of this type it will be rejected.
  e.g.
  ```code
  purpose: 'LB Lib PCR'
  ```

  The purpose field can be a list (for use when there are a number of valid options):
  e.g.
  ```code
  purpose: ['LB Lib PCR-XP', 'LTN Lib PCR XP']
  ```

  `states`
  The list of states that are valid for the labware in this bed. Prevents the users transferring from or into plates that are in the wrong state. Usually will contain just one state. If the labware is not in one of these states it will be rejected.
  e.g.
  ```code
  states: ['passed']
  ```

  `child`
  Indicates which other bed definition is the child of this bed. Used for relationship validation. The child bed specified must be defined in the same beds hash. Optional, child is not needed if the bed verification does not need to check a relationship exists.
  e.g.
  ```code
  child: bed(4).barcode
  ```
  The can be multiple children as a list (for splits):
  e.g.
  ```code
  'children' => [bed(15).barcode, bed(14).barcode]
  ```

  `parent`
  Indicates which other bed is the parent of this bed. Used for relationship validation. The parent bed specified must be defined in the same beds hash. Optional, parent or parents is not needed if the bed verification does not need to check a relationship exists.
  e.g.
  ```code
  parent: bed(7).barcode
  ```

  There can be multiple parents as a list (for merges):
  e.g.
  ```code
  parents: [bed(2).barcode, bed(5).barcode, bed(3).barcode, bed(6).barcode],
  ```

  `label`
  The label for the bed as it should be displayed in the bed verification screen GUI.
  e.g.
  ```code
  label: 'Bed 2'
  ```

## An example of multiple pairs of parallel transfers
Sometimes the liquid handler deck is large enough to accommodate two or more sets of transfers in parallel (aids throughput in the lab).
This example contains two pairs of beds (7 with 9, and 12 with 14). Note that the lab does not have to use both pairs, the bed verification code will validate just one pair if that's what they choose to use.
But validation will fail if you use a mismatched pair. e.g. bed 7 with 14 here.

```code
custom_robot(
  'star-96-post-cap-pcr-purification',
  name: 'STAR-96 LB Cap Lib PCR => LB Cap Lib PCR-XP',
  verify_robot: false,
  beds: {
    bed(7).barcode => {
      purpose: 'LB Cap Lib PCR',
      states: ['passed'],
      label: 'Bed 7'
    },
    bed(9).barcode => {
      purpose: 'LB Cap Lib PCR-XP',
      states: ['pending'],
      label: 'Bed 9',
      parent: bed(7).barcode,
      target_state: 'passed'
    },
    bed(12).barcode => {
      purpose: 'LB Cap Lib PCR',
      states: ['passed'],
      label: 'Bed 12'
    },
    bed(14).barcode => {
      purpose: 'LB Cap Lib PCR-XP',
      states: ['pending'],
      label: 'Bed 14',
      parent: bed(12).barcode,
      target_state: 'passed'
    }
  }
)
```

## A single labware preparation bed verification
Sometimes you just want a bed verification to check that a single plate is on the liquid handler deck at the correct location, without a transfer happening. In these cases the lab is typically doing some sort of preparation process or chemistry on the plate.

For these, you do not specify parent or child beds.

For example, this bed verification checks a single plate is in bed 5 and changes it's state, but there is no parent or child definition:

```code
custom_robot(
  'bravo-pf-post-shear-xp-prep',
  name: 'Bravo PF Post Shear XP Preparation',
  beds: {
    bed(5).barcode => {
      purpose: 'PF Post Shear XP',
      states: ['started'],
      label: 'Bed 5',
      target_state: 'passed'
    }
  }
)
```

NB. You do not have to change the state of a labware in a bed verification. It just makes sense in most cases to do so in order to control the appearance of buttons on the view in Limber and help 'lead' the user through their process.

## A sequential series of transfers within the same bed verification
Sometimes a liquid handler method performs a series of transfers in the same run. So rather than just A->B, it may perform A->B->C.

See {PermissivePresenter} to create child plates while the parent plate is still in a pending state.

Example with 3 steps:
```code
custom_robot(
  'bravo-pf-post-shear-xp-to-pf-lib-xp',
  name: 'Bravo PF Post Shear XP to PF Lib XP',
  beds: {
    car('1,3').barcode => {
      purpose: 'PF Post Shear XP',
      states: ['passed'],
      label: 'Carousel 1,3'
    },
    bed(6).barcode => {
      purpose: 'PF Lib',
      states: ['pending'],
      label: 'Bed 6',
      target_state: 'passed',
      parent: car('1,3').barcode
    },
    car('4,3').barcode => {
      purpose: 'PF Lib XP',
      states: ['pending'],
      label: 'Carousel 4,3',
      target_state: 'passed',
      parent: bed(6).barcode
    }
  }
)
```

Note above how the last two beds expect the plate to be in 'pending' state.
And that they each have a parent of the previous bed.

## A series of linked bed verifications
Sometimes you want to track a sequence of processes on the same robot.
For example, a plate may go through a preparation step, then it leaves the deck for a PCR process, then it is returned to the deck and the destination is added and a transfer happens etc.

For example, a preparation bed verification followed by a transfer bed verification:

```code
custom_robot(
  'beckman-lilys-96-stock-preparation',
  name: 'Beckman LILYS-96 Stock Preparation',
  require_robot: true,
  beds: {
    bed(9).barcode => {
      purpose: 'LILYS-96 Stock',
      states: ['passed'],
      label: 'Bed 9',
      target_state: 'passed'
    }
  }
)
```

And the transfer:
```code
custom_robot(
  'beckman-lilys-96-stock-to-lbsn-96-lysate',
  name: 'Beckman LILYS-96 Stock => LBSN-96 Lysate',
  require_robot: true,
  beds: {
    bed(9).barcode => {
      purpose: 'LILYS-96 Stock',
      states: ['passed'],
      label: 'Bed 9',
      target_state: 'passed'
    },
    bed(14).barcode => {
      purpose: 'LBSN-96 Lysate',
      states: ['pending'],
      label: 'Bed 14',
      target_state: 'passed',
      parent: bed(9).barcode
    }
  }
)
```

Note with the above that the same plate purpose is in bed 9 on both bed verifications.
Note that the first bed verification here doesn't do a transfer and doesn't change the state of the plate.
Note also that it is possible to insist that the same robot barcode is scanned for the second bed verification. To do that, in the second bed verification change
```code
require_robot: true,
```
to
```code
verify_robot: true,
```
(The downside of this is if the lab staff entered a string for the robot barcode in the first bed verification that they cannot then remember for the second, they are blocked from continuing. There have been support issues where that has happened. There is no way to verify that the string entered is a valid robot barcode or name, as not all robots are persisted in Sequencescape.)

> [TIP]
> - When developing just set the bed barcodes to any numbers if you don't yet have the real numbers (often the lab is still testing the liquid handler steps and doesn't finalise all the locations).
> - Note that you can use state to control when bed verification buttons appear on the Limber view. This helps to avoid confusion for the lab staff, it leads them through the sequence in the correct order. For example, you could have a series of bed verifications that transition a plate through a series of states, e.g. pending to started, then started to processed_1, then processed_1 to processed_2, and finally processed_2 to passed. The buttons for each transition will only appear when the plate is in the valid starting state for the next transition.