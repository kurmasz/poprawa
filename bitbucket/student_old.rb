def get_mark_old(item)
  mark_values = { "e" => 2, "m" => 3, "p" => 4, "x" => 5, "." => 6, "?" => 6 }
  mark = @marks[item]
  return mark if mark.nil? || mark.length <= 1
  $stderr.puts "Mark for #{item} is nil" if mark.nil?
  mark.chars.each do |v|
    $stderr.puts "Unknown mark for #{item}:  =>#{v}<=" unless mark_values.has_key?(v)
  end

  mark.chars.sort { |a, b| mark_values[a] <=> mark_values[b] }.first
end