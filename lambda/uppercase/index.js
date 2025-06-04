exports.handler = async (event) => {
    const body = JSON.parse(event.body);
    const text = body.text;

    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({
            result: text.toUpperCase()
        })
    };
}; 