$(document).ready(function () {
    $('form#id-data').submit(function (e) {
        var url = "/postform";
        $.ajax({
            type: "POST",
            url: url,
            data: $('form#id-data').serialize(),
            success: function (res) {
                if (res.status == 'success') {

                    if ($('span.form-error').length) {
                        $('span.form-error').remove();
                    }

                    $('#submit-btn').removeClass('btn-primary').addClass('btn-success').text('Success');
                    setTimeout(function () {
                        $('#submit-btn').removeClass('btn-success').addClass('btn-primary').text('Submit');
                    }, 500);
                    $('#id-data')[0].reset();

                }

                if (res.status == 'error') {
                    if ($('span.form-error').length) {
                        $('span.form-error').remove();
                    }
                    if ("id_value" in res.message) {
                        $('#form-id_value').after('<span style="color: red;" class="form-error">' + res.message.id_value[0] + '</span>');
                    }
                    if ("id_tag" in res.message) {
                        $('#form-id_tag').after('<span style="color: red;" class="form-error">' + res.message.id_tag[0] + '</span>');
                    }


                    $('#submit-btn').removeClass('btn-primary').addClass('btn-danger').text('Error');
                    setTimeout(function () {
                        $('#submit-btn').removeClass('btn-danger').addClass('btn-primary').text('Submit');
                    }, 500);
                }
            }
        });
        e.preventDefault();
    });

    websocketClient();

    // inject CSRF token into our AJAX request.
    $.ajaxSetup({
        beforeSend: function (xhr, settings) {
            if (!/^(GET|HEAD|OPTIONS|TRACE)$/i.test(settings.type) && !this.crossDomain) {
                xhr.setRequestHeader("X-CSRFToken", "{{ form.csrf_token._value() }}")
            }
        }
    });


});


function websocketClient() {

    var namespace = '/logging';
    var socket = io.connect(location.protocol + '//' + document.domain + ':' + location.port +
        namespace, {
            secure: true
        });

    socket.on('message', function (res) {

        if (res.data == 'ts started') {
            socket.emit('message', {
                data: 'you can send data now'
            });
        }
    });

    socket.on('progress', function (res) {
        if (res.data) {
            $('#alert-progress').text(res.data);
        }
    });

    socket.on('connect', function () {
        console.log('websocket client connected');
    });

}