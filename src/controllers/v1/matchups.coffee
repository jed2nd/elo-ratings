User = model('v1/user')
config = include('../config')

module.exports =
  show: (ctx, res) ->
    id = ctx.params.id

    user = yield User.findByName(id)
    user ?=
      _id: ""
      name: "New User"
      rating: 2000
      matches: 0
      wins: 0

    usersToPlay = yield findGoodMatchup(user)

    res.ok(usersToPlay)

  list: (ctx, res) ->
    users = yield User.listAll()

    if ctx.req.query?.hide_retired == 'true'
      users = users.filter((u) -> !u.retired)

    numUsers = users.length

    for user in users
      user.rank = numUsers - users.filter((u) -> u.rating < user.rating).length
      matchups = yield findGoodMatchup(user, {hide_retired: ctx.req.query?.hide_retired})
      user.bestMatchup = matchups[0]

    users.sort((a,b) -> b.rating - a.rating)
    res.ok(users)

findGoodMatchup = (user, opts) ->
  allUsers = yield User.listAll()
  allUsers = allUsers.filter((u) ->
    if opts?.hide_retired?
      return false if u.retired
    return u._id.toString() != user._id.toString() and u.matches > 3
  )

  for u in allUsers when u._id.toString() != user._id.toString()
    u.crossPopulate = -1 * (user.rating - u.rating) * (user.wins - u.wins)
    ratingDiff = Math.abs(user.rating - u.rating)
    expDiff = Math.abs(user.matches - u.matches)
    u.matchupScore = 2000/(ratingDiff + expDiff)
    { ptsOnTheLine, winExp } = pointsOnTheLine(user, u)
    u.ptsOnTheLine = ptsOnTheLine
    u.winExp = winExp * 100
    if ptsOnTheLine * 2 > ratingDiff
      if user.rating > u.rating
        u.ratingsSwap = 'On Loss'
      else
        u.ratingsSwap = 'On Win'

  return allUsers.sort((a,b) -> b.crossPopulate - a.crossPopulate)

pointsOnTheLine = (p1, p2) ->
  p1RatingAdv = p1.rating - p2.rating
  p2RatingAdv = p2.rating - p1.rating

  p1WinExp = 1 / (Math.pow(10, ((0-p1RatingAdv) / 400)) + 1)
  p2WinExp = 1 / (Math.pow(10, ((0-p2RatingAdv) / 400)) + 1)

  thisK = config.kVal

  return { ptsOnTheLine: thisK * p1WinExp, winExp: p1WinExp }
