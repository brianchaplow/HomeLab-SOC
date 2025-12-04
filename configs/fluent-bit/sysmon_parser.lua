-- Sysmon Field Extractor for Fluent Bit
-- Extracts fields from StringInserts array based on EventID

function extract_sysmon_fields(tag, timestamp, record)
    local event_id = record["EventID"]
    local inserts = record["StringInserts"]
    
    -- Only process if we have StringInserts array
    if inserts == nil or type(inserts) ~= "table" then
        return 0, 0, 0
    end
    
    -- Sysmon Event ID 1: Process Creation
    if event_id == 1 then
        record["RuleName"] = inserts[1]
        record["UtcTime"] = inserts[2]
        record["ProcessGuid"] = inserts[3]
        record["SysmonProcessId"] = inserts[4]
        record["Image"] = inserts[5]
        record["FileVersion"] = inserts[6]
        record["Description"] = inserts[7]
        record["Product"] = inserts[8]
        record["Company"] = inserts[9]
        record["OriginalFileName"] = inserts[10]
        record["CommandLine"] = inserts[11]
        record["CurrentDirectory"] = inserts[12]
        record["User"] = inserts[13]
        record["LogonGuid"] = inserts[14]
        record["LogonId"] = inserts[15]
        record["TerminalSessionId"] = inserts[16]
        record["IntegrityLevel"] = inserts[17]
        record["Hashes"] = inserts[18]
        record["ParentProcessGuid"] = inserts[19]
        record["ParentProcessId"] = inserts[20]
        record["ParentImage"] = inserts[21]
        record["ParentCommandLine"] = inserts[22]
        record["ParentUser"] = inserts[23]
        return 1, timestamp, record
    
    -- Sysmon Event ID 3: Network Connection
    elseif event_id == 3 then
        record["RuleName"] = inserts[1]
        record["UtcTime"] = inserts[2]
        record["ProcessGuid"] = inserts[3]
        record["SysmonProcessId"] = inserts[4]
        record["Image"] = inserts[5]
        record["User"] = inserts[6]
        record["Protocol"] = inserts[7]
        record["Initiated"] = inserts[8]
        record["SourceIsIpv6"] = inserts[9]
        record["SourceIp"] = inserts[10]
        record["SourceHostname"] = inserts[11]
        record["SourcePort"] = inserts[12]
        record["SourcePortName"] = inserts[13]
        record["DestinationIsIpv6"] = inserts[14]
        record["DestinationIp"] = inserts[15]
        record["DestinationHostname"] = inserts[16]
        record["DestinationPort"] = inserts[17]
        record["DestinationPortName"] = inserts[18]
        return 1, timestamp, record
    
    -- Sysmon Event ID 11: File Created
    elseif event_id == 11 then
        record["RuleName"] = inserts[1]
        record["UtcTime"] = inserts[2]
        record["ProcessGuid"] = inserts[3]
        record["SysmonProcessId"] = inserts[4]
        record["Image"] = inserts[5]
        record["TargetFilename"] = inserts[6]
        record["CreationUtcTime"] = inserts[7]
        record["User"] = inserts[8]
        return 1, timestamp, record
    
    -- Sysmon Event ID 13: Registry Value Set
    elseif event_id == 13 then
        record["RuleName"] = inserts[1]
        record["EventType"] = inserts[2]
        record["UtcTime"] = inserts[3]
        record["ProcessGuid"] = inserts[4]
        record["SysmonProcessId"] = inserts[5]
        record["Image"] = inserts[6]
        record["TargetObject"] = inserts[7]
        record["Details"] = inserts[8]
        record["User"] = inserts[9]
        return 1, timestamp, record
    
    -- Sysmon Event ID 22: DNS Query
    elseif event_id == 22 then
        record["RuleName"] = inserts[1]
        record["UtcTime"] = inserts[2]
        record["ProcessGuid"] = inserts[3]
        record["SysmonProcessId"] = inserts[4]
        record["QueryName"] = inserts[5]
        record["QueryStatus"] = inserts[6]
        record["QueryResults"] = inserts[7]
        record["Image"] = inserts[8]
        record["User"] = inserts[9]
        return 1, timestamp, record
    
    -- Sysmon Event ID 2: File Creation Time Changed
    elseif event_id == 2 then
        record["RuleName"] = inserts[1]
        record["UtcTime"] = inserts[2]
        record["ProcessGuid"] = inserts[3]
        record["SysmonProcessId"] = inserts[4]
        record["Image"] = inserts[5]
        record["TargetFilename"] = inserts[6]
        record["CreationUtcTime"] = inserts[7]
        record["PreviousCreationUtcTime"] = inserts[8]
        record["User"] = inserts[9]
        return 1, timestamp, record
    end
    
    -- No changes for other events
    return 0, 0, 0
end