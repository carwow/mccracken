# McCracken::Resource
class Member < McCracken::Resource
  self.type = :members

  def name
    document[:name]
  end
end
