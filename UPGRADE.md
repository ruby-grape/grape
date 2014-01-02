# Upgrading

## upgrading to 0.6.2

In grape <= 0.6.1, `group`, `optional` and `requires` with block accepted
either an Array or a Hash.

In grape 0.6.2, these have an additional `type` attribute which defaults
to `Array`. This means that without a `type` attribute, these nested parameters
will no longer accept a single hash, only an array (of hashes).

```ruby
params do
  requires :id, type: Integer
  group :name do
    requires :first_name
    requires :last_name
  end
end
```

Whereas in 0.6.1 this accepted the following json,

```json
{
  "id": 1,
  "name": {
    "first_name": "John",
    "last_name" : "Doe"
  }
}
```

it no longer does in 0.6.2. The params block should now read:

```ruby
params do
  requires :id, type: Integer
  requires :name, type: Hash do
    requires :first_name
    requires :last_name
  end
end
```
