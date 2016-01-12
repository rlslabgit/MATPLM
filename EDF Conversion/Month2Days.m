function [ daysInMonth ] = Month2Days( monthnum )
%Month2Days Converts the month number to the number of days in that month
%       switch monthnum
%         case 1 % Jan
%             daysInMonth = 31;
%         case 2 % Feb
%             daysInMonth = 28;
%         case 3 % Mar
%             daysInMonth = 31;
%         case 4 % Apr
%             daysInMonth = 30;
%         case 5 % May
%             daysInMonth = 31;
%         case 6 % Jun
%             daysInMonth = 30;
%         case 7 % Jul
%             daysInMonth = 31;
%         case 8 % Aug
%             daysInMonth = 31;
%         case 9 % Sep
%             daysInMonth = 30;
%         case 10 % Oct
%             daysInMonth = 31;
%         case 11 % Nov
%             daysInMonth = 30;
%         case 12 % Dec
%             daysInMonth = 31;
%     end

    switch monthnum
        case 0
            daysInMonth = 0;
        case 1 % Jan
            daysInMonth = 31;
        case 2 % Feb
            daysInMonth = 28;
        case 3 % Mar
            daysInMonth = 31;
        case 4 % Apr
            daysInMonth = 30;
        case 5 % May
            daysInMonth = 31;
        case 6 % Jun
            daysInMonth = 30;
        case 7 % Jul
            daysInMonth = 31;
        case 8 % Aug
            daysInMonth = 31;
        case 9 % Sep
            daysInMonth = 30;
        case 10 % Oct
            daysInMonth = 31;
        case 11 % Nov
            daysInMonth = 30;
        case 12 % Dec
            daysInMonth = 31;
    end

end

