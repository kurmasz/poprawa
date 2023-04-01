

h = {
  name: 'bob'
}

hs = h.to_s

puts hs

h2 = eval hs

puts h2[:name]