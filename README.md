# Shopiexrl

[![Build Status](https://travis-ci.com/byjord/Shopiexrl.svg?branch=master)](https://travis-ci.com/byjord/Shopiexrl)
[![Coverage Status](https://coveralls.io/repos/byjord/Shopiexrl/badge.svg?branch=master)](https://coveralls.io/github/byjord/Shopiexrl?branch=master)

Making sure to not to overflow a Shopify stores bucket

## Quick Start

Add Shopiexrl to your mix.exs. Currently only on GitHub:

```elixir
def deps do
  [{:Shopiexrl, github: "https://github.com/byjord/Shopiexrl"}]
end
```

Fetching dependencies and running on elixir console:

```console
$ mix deps.get
$ iex -S mix
```

## What is happening here?

![current state](https://raw.githubusercontent.com/byjord/Assets/master/ShopiexRL.png)

---

## Future plan?

![Future plan](https://raw.githubusercontent.com/byjord/Assets/master/FutureShopiexRL.png)

### Journey

For every store that you're sending requests to a new store group is created that will contain a pool controller, assignable connection pool, assigned lock pool, and a cool down pool.
Before a request is sent out to the Shopify API we request a lock from the assignable connection pool, this makes sure that there is still room in the bucket for our call. When assignment is made the lock is moved to the Assigned Pool where the lock will stay until we release it, once released the lock is moved to the cool down pool.

### Can this fall out of sync with Shopifys count?

Yes. ShopiexRL is not 100% accurate at the moment with staying in sync with Shopify's leaky bucket algorithm. Here we're attempting to manage large amounts of requests and avoid ever triggering a `422` response.
The main point of lost accuracy is with the movement from the locked pool to the cool down pool. Because we cannot guarantee that a: this will happen exactly as the request is processed by Shopify, increasing Shopify's internal pool count, b: our leak event might be triggered at different times EG: we both run at 500ms intervals but 500ms elapses at different realtime milliseconds. Our next leak at 4:43:00.0349, There next leak: 4:43:00.0350.

## Pools

### Connection Pool (default pool)

Available locks that can be assigned to processes that want to make a request.

### Lock Pool

Any lock that has been assigned to a process / requestor, and not handed back (request is still pending)

### Cool down Pool

Where a lock goes to be processed and put back into the Connection Pool ready for the next requestor.
