describe 'Mozart.Cookies', ->

  afterEach ->
    Mozart.Cookies.removeCookie 'name'

  it 'should store and retrieve simple cookies', ->
    expected = 'value'
    Mozart.Cookies.setCookie 'name', expected
    actual = Mozart.Cookies.getCookie 'name'
    expect(actual).toEqual(expected)

  it 'should have a cookie after a cookie has been set', ->
    Mozart.Cookies.setCookie 'name', 'value'
    actual = Mozart.Cookies.hasCookie 'name'
    expect(actual).toBe(true)

  it 'should remove cookies when requested', ->
    Mozart.Cookies.setCookie 'name', 'value'
    Mozart.Cookies.removeCookie 'name'
    actual = Mozart.Cookies.hasCookie 'name'
    expect(actual).toBe(false)

  it 'should support cookie names composed of characters outside the Basic Latin Unicode block', ->
    expected = 'value'
    Mozart.Cookies.setCookie '名前', expected
    actual = Mozart.Cookies.getCookie '名前'
    expect(actual).toEqual(expected)
    Mozart.Cookies.removeCookie '名前'

  it 'should support cookie values composed of characters outside the Basic Latin Unicode block', ->
    expected = 'Küth'
    Mozart.Cookies.setCookie 'name', expected
    actual = Mozart.Cookies.getCookie 'name'
    expect(actual).toEqual(expected)

  it 'should expire cookies set with the max-age option after max-age seconds', ->
    # Drooling retard mode for IE8, which does not support max-age.
    unless $.browser.msie
      Mozart.Cookies.setCookie 'name', 'value',
        'max-age': -1
      actual = Mozart.Cookies.getCookie 'name'
      expect(actual).toBeNull()
    else
      expect(true).toBeTruthy()

  it 'should expire cookies set with the expires option at the specified date', ->
    Mozart.Cookies.setCookie 'name', 'value',
      expires: new Date()
    actual = Mozart.Cookies.getCookie 'name'
    expect(actual).toBeNull()
