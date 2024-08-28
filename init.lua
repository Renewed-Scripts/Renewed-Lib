Renewed = setmetatable({}, {
    __index = function(self, index)
        self[index] = function(...)
            return exports['Renewed-Lib'][index](nil, ...)
        end

        return self[index]
    end
})
