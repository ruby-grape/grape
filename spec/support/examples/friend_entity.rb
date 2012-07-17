class FriendEntity < Grape::Entity
  root 'friends', 'friend'
  expose :name, :email
end
