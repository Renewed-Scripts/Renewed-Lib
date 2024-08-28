Renewed = {}

setmetatable(Renewed, {
    __call = function(self, ...)
        return exports['Renewed-Lib']:self(...)
    end
})