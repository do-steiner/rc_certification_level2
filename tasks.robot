
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
Library             RPA.RobotLogListener
Library             RPA.Desktop

*** Variables ***
${ORDERS_CSV_OUTPUT_PATH}=          ${OUTPUT_DIR}${/}data${/}orders.csv
${TEMP_ROBOT_SCREENSHOT_PATH}=      ${OUTPUT_DIR}${/}data${/}temp${/}robot-preview.png
${RECEIPTS_OUTPUT_FOLDER}=          ${OUTPUT_DIR}${/}data${/}receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders_csv_url}=    Input CSV URL
    ${orders_url}=    Obtain order website URL from vault
    Open the robot order website    ${orders_url}
    ${orders}=    Get orders    ${orders_csv_url}
    FOR    ${row}    IN    @{orders}
        Log    Current row is: ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    0.5 sec    Submit the order
        ${pdf_path}=    Store the receipt as a PDF file    ${row}[Order number]
        ${robot_image_path}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${robot_image_path}    ${pdf_path}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close All Browsers
    

*** Keywords ***

Input CSV URL
    Add heading    URL to download CSV file
    Add text    A good URL would be: https://robotsparebinindustries.com/orders.csv    size=Small
    Add text input    url
    ...    label=URL
    ...    placeholder=Enter CSV URL here
    ${result}=    Run dialog
    RETURN    ${result.url}    

Obtain order website URL from vault
    ${orders_url}=    Get Secret    robot-orders
    Log    Obtained robot order website URL from vault is: ${orders_url}[url]
    RETURN    ${orders_url}[url]
 
Open the robot order website
    [Arguments]    ${orders_url}
    Open Available Browser    ${orders_url}

Get orders 
    [Arguments]    ${orders_csv_url}
    TRY
        Download    ${orders_csv_url}    overwrite=True    target_file=${ORDERS_CSV_OUTPUT_PATH}

    EXCEPT 
        Log    Failed to downlaod orders CSV file from provided URL.   
        Fail   Failed to download CSV 
    END
    ${orders}=    Read table from CSV    ${ORDERS_CSV_OUTPUT_PATH}
    Log    Found columns: ${orders.columns}
    RETURN    ${orders}


Close the annoying modal
    Click Button    xpath: //*[contains(text(), "OK")]

Fill the form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    xpath: //input[@type="number"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview


Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_path}=    Set Variable    ${RECEIPTS_OUTPUT_FOLDER}${/}receipt_${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${image_output_path}=    Set Variable    ${TEMP_ROBOT_SCREENSHOT_PATH}
    Screenshot    id:robot-preview-image    ${image_output_path}
    RETURN    ${image_output_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${image_path}    ${pdf_path}
    Add Watermark Image To Pdf    ${image_path}    ${pdf_path}    source_path=${pdf_path}
    Close Pdf    ${pdf_path}

Submit the order
    Click Button    id:order
    Mute Run On Failure    Element Should Be Visible
    Element Should Be Visible    id:receipt

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${RECEIPTS_OUTPUT_FOLDER}    ${OUTPUT_DIR}/receipts.zip