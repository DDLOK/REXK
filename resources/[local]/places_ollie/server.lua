local PRICES = { snack = 5, pistol = 200, repair = 150, fuel = 40 }

RegisterNetEvent('places_ollie:buy')
AddEventHandler('places_ollie:buy', function(what, price, _extra)
    local src = source
    local expected = PRICES[what]
    if not expected or price ~= expected then return end  -- anti-tamper
    local ok = exports.cash_ollie:removeCash(src, price)
    TriggerClientEvent('places_ollie:buyResult', src, what, ok, price)
end)

RegisterNetEvent('places_ollie:refund')
AddEventHandler('places_ollie:refund', function(amount)
    local src = source
    if amount and amount > 0 and amount <= 500 then
        exports.cash_ollie:addCash(src, amount)
    end
end)

print('^2[places_ollie]^7 loaded - ' .. #PLACES .. ' interactable spots')
