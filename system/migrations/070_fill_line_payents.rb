# Sequel.migration do
#   up do
#     run '
#       insert into line_payments (o_id, payment_type, payment_code, payment_ammount, created_at) select o_id, "CASH", "", amount, created_at from book_records where o_id > 0 and type = "Venta mostrador";
#     '
#   end

#   down do
#     run 'truncate table line_payments;'
#   end
# end
