React = require 'react'
_ = require "underscore"
{EventedIFrame} = require 'nylas-component-kit'
{Utils} = require 'nylas-exports'

class EmailFrame extends React.Component
  @displayName = 'EmailFrame'

  render: =>
    <EventedIFrame ref="iframe" seamless="seamless" />

  componentDidMount: =>
    @_mounted = true
    @_writeContent()
    @_setFrameHeight()

  componentWillUnmount: =>
    @_mounted = false

  componentDidUpdate: =>
    @_writeContent()
    @_setFrameHeight()

  shouldComponentUpdate: (newProps, newState) =>
    # Turns out, React is not able to tell if props.children has changed,
    # so whenever the message list updates each email-frame is repopulated,
    # often with the exact same content. To avoid unnecessary calls to
    # _writeContent, we do a quick check for deep equality.
    !_.isEqual(newProps, @props)

  _writeContent: =>
    wrapperClass = if @props.showQuotedText then "show-quoted-text" else ""
    doc = React.findDOMNode(@).contentDocument
    doc.open()

    EmailFixingStyles = document.querySelector('[source-path*="email-frame.less"]')?.innerText
    EmailFixingStyles = EmailFixingStyles.replace(/.ignore-in-parent-frame/g, '')
    if (EmailFixingStyles)
      doc.write("<style>#{EmailFixingStyles}</style>")
    doc.write("<div id='inbox-html-wrapper' class='#{wrapperClass}'>#{@_emailContent()}</div>")
    doc.close()

    # Notify the EventedIFrame that we've replaced it's document (with `open`)
    # so it can attach event listeners again.
    @refs.iframe.documentWasReplaced()

  _setFrameHeight: =>
    _.defer =>
      return unless @_mounted
      domNode = React.findDOMNode(@)
      doc = domNode.contentDocument
      height = doc.getElementById("inbox-html-wrapper").scrollHeight
      if domNode.height != "#{height}px"
        domNode.height = "#{height}px"

      unless domNode?.contentDocument?.readyState is 'complete'
        @_setFrameHeight()

  _emailContent: =>
    email = @props.children

    # When showing quoted text, always return the pure content
    if @props.showQuotedText
      email
    else
      Utils.stripQuotedText(email)
      

module.exports = EmailFrame
