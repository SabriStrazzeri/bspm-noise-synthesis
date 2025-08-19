function structValues = readStructWithFields(struct, cavityType)
    namesStruct = fieldnames(struct);
    numStruct  = size(namesStruct,1);
    structValues = cell(numStruct,1);
    for i=1:1:numStruct
        name_index  = find(strcmp(namesStruct,strcat('Tags',num2str(i-1))));
        nameStruct = struct.(string(namesStruct(name_index)));
        if isempty(nameStruct)
            if strcmp(cavityType, 'Atria')
                structValues{i} = 'RA_REGION0'; 
            elseif strcmp(cavityType, 'Ventricles')
                structValues{i} = 'BASE'; 
            end 
        else
            structValues{i} = nameStruct;
        end 
    end
    structValues = structValues'; % original structValues not organized
end 