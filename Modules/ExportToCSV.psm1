# Function to handle exporting data to CSV
function Export-DataToCsv ($Data, $CsvFile) {
    if (-not (Test-Path $CsvFile)) {
        # Create the CSV file with headers
        $Data | Export-Csv -LiteralPath $CsvFile -NoTypeInformation -UseCulture -Force
    } else {
        # Append data to existing CSV file
        $Data | Export-Csv -LiteralPath $CsvFile -NoTypeInformation -Append -UseCulture -Force
    }
}