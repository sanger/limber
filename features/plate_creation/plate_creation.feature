Feature: Plate creation
  In order to move samples through the pulldown pipeline
  As a ordinary user
  I want create new plates from source plates
  
  Scenario: creating a plate from a Stock plate
    Given I am on the homepage
    When I enter a valid user barcode
      And I enter a valid Source Plate barcode
    Then I am presented with a screen allowing me to create a destination plate
  
  Scenario: Finding a plate page by page
    Given I am on the homepage
    When I enter a valid user barcode
      And I press "Find User"
    Then I am on the plate search page
  
  
  
  
  

  
